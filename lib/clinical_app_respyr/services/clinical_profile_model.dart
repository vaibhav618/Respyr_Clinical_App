class ClinicalProfileModelList {
  int? id;
  String? subjectId;
  String? clinicName;
  String? profileName;
  String? gender;
  String? region;
  int? age;
  double? height;
  double? weight;
  String? dttm;

  ClinicalProfileModelList(
      {this.id,
      this.subjectId,
      this.clinicName,
      this.profileName,
      this.gender,
      this.age,
      this.height,
      this.weight,
      this.region,
      this.dttm});

  ClinicalProfileModelList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    subjectId = json['subject_id'];
    clinicName = json['clinic_name'];
    profileName = json['profile_name'];
    gender = json['gender'];
    age =
        json['age'] is int ? json['age'] : int.tryParse(json['age'].toString());
    height = _parseDouble(json['height']);
    weight = _parseDouble(json['weight']);
    region =(json['region']);
    dttm = json['dttm'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['subject_id'] = subjectId;
    data['clinic_name'] = clinicName;
    data['profile_name'] = profileName;
    data['gender'] = gender;
    data['age'] = age;
    data['height'] = height;
    data['weight'] = weight;
    data['region'] = region;
    data['dttm'] = dttm;
    return data;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
