// Bottom Sheet
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/issue_item.dart';

class CheckboxBottomSheet extends StatefulWidget {
  final List<IssueItem> items;
  final List<IssueItem> initiallySelected;

  const CheckboxBottomSheet({super.key,
    required this.items,
    required this.initiallySelected,
  });

  @override
  CheckboxBottomSheetState createState() => CheckboxBottomSheetState();
}

class CheckboxBottomSheetState extends State<CheckboxBottomSheet> {
  late List<IssueItem> selected;

  @override
  void initState() {
    super.initState();
    selected = List<IssueItem>.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child:  Column(
        mainAxisSize: MainAxisSize.min, // THIS makes it wrap content

        children: [
          SizedBox(height: 50,),
          Text('Select one or more',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF535359),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.30,
              )
          ),
          SizedBox(height: 20,),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                IssueItem item = widget.items[index];
                bool isChecked = selected.contains(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F7FA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child:
                    CheckboxListTile(
                      title: Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF252525),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.30,
                        )
                      ),
                      value: isChecked,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            selected.add(item);
                          } else {
                            selected.remove(item);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                      activeColor: Colors.green,         // Checkbox fill color when checked
                      checkColor: Colors.white,          // Tick color
                      tileColor: Colors.green[50],       // Background color for tile
                      shape: RoundedRectangleBorder(     // Rounded corners for tile
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    )

                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style:ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC7C6CE),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16)
                  ) ,
                  child: Text('Cancel',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF252525),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                      letterSpacing: 0.30,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8,),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selected);
                  },
                  style:ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF308BF9),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16)
                  ) ,
                  child: Text('Done',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.10,
                      letterSpacing: 0.30,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
