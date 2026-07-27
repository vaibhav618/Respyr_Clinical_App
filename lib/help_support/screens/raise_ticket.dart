import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:respyr_clinical/help_support/widgets/issue_tag_fill.dart';

import 'package:respyr_clinical/shared/urls.dart';
import '../models/issue_cat_list.dart';
import '../models/issue_item.dart';
import '../widgets/issue_bottom_sheet.dart';


class RaiseTicket extends StatefulWidget {
  final String loginId;
  const RaiseTicket({super.key, required this.loginId});

  @override
  State<RaiseTicket> createState() => _RaiseTicketState();
}

class _RaiseTicketState extends State<RaiseTicket> {
  final List<XFile> selectedImages = [];
  final TextEditingController issueController = TextEditingController();
  bool isLoading = false;

  Future<void> _showImageSourceSelector({int? replaceIndex}) async {
    if (replaceIndex == null && selectedImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 2 images.')),
      );
      return;
    }

    XFile? pickedImage;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                tileColor: const Color(0xFFF5F7FA), // Background color for the ListTile
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                ), // Inner padding for the tile
                leading: SvgPicture.asset("assets/svg_icons/hugeicons_camera-01.svg"),
                title:  Text('Camera',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.30,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(ImageSource.camera)) {
                    pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
                    _addOrReplaceImage(pickedImage, replaceIndex);
                  }
                },
              ),
              SizedBox(height: 20,),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                tileColor: const Color(0xFFF5F7FA), // Background color for the ListTile
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                ), // Inner padding for the tile
                leading: SvgPicture.asset("assets/svg_icons/hugeicons_google-photos.svg"),
                title:  Text('Gallery',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF252525),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.30,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (await _requestPermission(ImageSource.gallery)) {
                    pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                    _addOrReplaceImage(pickedImage, replaceIndex);
                  }
                },
              ),

            ],
          ),
        );
      },
    );
  }



  Future<void> _addOrReplaceImage(XFile? pickedImage, int? replaceIndex) async {
    if (pickedImage == null) return;

    // Convert XFile to File first
    File file = File(pickedImage.path);
    const maxSize = 2 * 1024 * 1024; // 2MB

    if (await file.length() > maxSize) {
      final dir = await Directory.systemTemp.createTemp();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
      );

      if (compressedFile == null || await compressedFile.length() > maxSize) {


        Get.snackbar(
          'Failed',                    // Title
          'Image size must be under 2MB (even after compression).',    // Message
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
        return;
      }

      pickedImage = XFile(compressedFile.path); // Convert back to XFile
    }

    setState(() {
      if (replaceIndex != null) {
        selectedImages[replaceIndex] = pickedImage!;
      } else {
        selectedImages.add(pickedImage!);
      }
    });
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return await Permission.camera.request().isGranted;
    } else {
      if (Platform.isAndroid) {
        return await Permission.photos.request().isGranted || await Permission.storage.request().isGranted;
      } else {
        return await Permission.photos.request().isGranted;
      }
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  Future<void> _submitTicket(BuildContext context) async {
    if (issueController.text.trim().isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue')),
      );
      return;
    }

    // Validate all image sizes before uploading
    for (var image in selectedImages) {
      final fileSize = File(image.path).lengthSync();
      const maxSize = 2 * 1024 * 1024;
      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("One or more images exceed 2MB. Please upload smaller images.")),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    var uri = Uri.parse(Urls.raiseIssue);
    var request = http.MultipartRequest("POST", uri);

    request.fields['login_id'] = widget.loginId;
    request.fields['issue_description'] = issueController.text.trim();
    request.fields['title'] = getSelectedItemNames(selectedItems);

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        String key = i == 0 ? 'image1' : 'image2';
        var file = File(selectedImages[i].path);

        request.files.add(await http.MultipartFile.fromPath(
          key,
          file.path,
          contentType: MediaType('image', _getMimeType(file.path)),
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 && responseData.contains("success")) {
        setState(() {
          selectedItems.clear();

        });
        Get.snackbar(
          'Your issue has been raised',                    // Title
          responseData,    // Message
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',                    // Title
          responseData,    // Message
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Failed',                    // Title
        "Network error",    // Message
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<File?> compressImage(XFile fileX) async {
    final File file = File(fileX.path); // ✅ Convert XFile to File

    final dir = await Directory.systemTemp.createTemp();
    final String targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final File? compressedFile = (await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
    )) as File?;

    return compressedFile;
  }

  List<IssueItem> selectedItems = [];

  void _showCheckboxBottomSheet() async {
    List<IssueItem> allItems = issueCatList;
    final result = await showModalBottomSheet<List<IssueItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return CheckboxBottomSheet(
          items: allItems,
          initiallySelected: selectedItems,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedItems = result;
      });
    }
  }


  String getSelectedItemNames(List<IssueItem> selectedItems) {
    return selectedItems.map((item) => item.name).join(',');
  }


  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 36,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("Choose one or more topics below that best describe your issue.",
            style: GoogleFonts.poppins(
              color: const Color(0xFF535359),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.30,
            ),
          ),
        ),
        SizedBox(height: 23,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: const Color(0xFFC7C6CE),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showCheckboxBottomSheet();
                    },
                    style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedItems.isEmpty ? "Select all that apply":
                          'Selected(${selectedItems.length})',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF252525),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.10,
                            letterSpacing: -0.30,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_outlined, color:  const Color(0xFF252525),),
                      ],
                    ),
                  ),
                ),
                issuePillContainer(selectedItems, true),
              ],
            ),
          ),
        ),
        SizedBox(height: 23,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextFormField(
            controller: issueController,
            maxLines: 3,
            decoration:  InputDecoration(
              hintText: 'Describe your issue',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.24,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFFC7C6CE), width:1),
                borderRadius: BorderRadius.all(Radius.circular(10)),

              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFFC7C6CE), width:1),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: const Color(0xFFC7C6CE),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Add images(2)",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF252525),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                        letterSpacing: -0.30,
                      ),
                    ),
                    Spacer(),
                    OutlinedButton(
                        onPressed: selectedImages.length >= 2 ? null : () => _showImageSourceSelector(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFC7C6CE), width: 0.5),
                        ),
                        child: Text("Upload",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF308BF9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.10,
                            letterSpacing: -0.24,
                          ),
                        )
                    )
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: List.generate(selectedImages.length, (index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageSourceSelector(replaceIndex: index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(selectedImages[index].path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                            onPressed: () {
                              setState(() {
                                selectedImages.removeAt(index);
                              });
                            },
                          ),
                        )
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _submitTicket(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF308BF9),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: isLoading
                  ?  CircularProgressIndicator(color: Colors.white)
                  :  Text("Submit", style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.10,
                letterSpacing: 0.30,
              )),
            ),
          ),
        )
      ],
    );
  }
}


