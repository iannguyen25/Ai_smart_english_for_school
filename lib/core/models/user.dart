class UserModel {
  String? authEmail;
  String? userId;
  String? id;
  String? system;
  String? displayName;
  String? provider;
  String? providerUid;
  String? password;
  String? firstName;
  String? lastName;
  String? firstNameKata;
  String? lastNameKata;
  String? phone;
  String? zipcode;
  String? pref;
  String? addr1;
  String? addr2;
  String? profileUrl;
  String? websiteUrl;
  String? imageUrl;
  String? registerDate;
  String? phoneToken;
  String? unregist;
  bool? active;

  UserModel(
      {this.authEmail,
      this.displayName,
      this.addr1,
      this.addr2,
      this.firstName,
      this.lastNameKata,
      this.imageUrl,
      this.lastName,
      this.firstNameKata,
      this.password,
      this.phone,
      this.phoneToken,
      this.pref,
      this.profileUrl,
      this.provider,
      this.providerUid,
      this.registerDate,
      this.unregist,
      this.websiteUrl,
      this.id,
      this.system,
      this.active,
      this.userId,
      this.zipcode});
  static UserModel fromJson(Map map) {
    return UserModel(
        id: map['auth_id'],
        userId: map['auth_user_id'],
        system: map['auth_system'],
        provider: map['auth_provider'],
        providerUid: map['auth_provider_uid'],
        password: map['auth_password'],
        authEmail: map['auth_email'],
        displayName: map['auth_display_name'],
        lastName: map['auth_last_name'],
        firstName: map['auth_first_name'],
        firstNameKata: map['auth_first_name_kana'],
        lastNameKata: map['auth_last_name_kana'],
        phone: map['auth_phone_no'],
        zipcode: map['auth_zipcode'],
        pref: map['auth_pref'],
        addr1: map['auth_addr1'],
        addr2: map['auth_addr2'],
        profileUrl: map['auth_profile_url'],
        websiteUrl: map['auth_website_url'],
        imageUrl: map['auth_image_url'],
        registerDate: map['auth_regist'],
        phoneToken: map['auth_phone_token'],
        unregist: map['auth_unregist'],
        active: map['active']);
  }

  Map toJson() {
    return {
      'auth_id': id,
      'auth_user_id': userId,
      'auth_system': system,
      'auth_provider': provider,
      'auth_provider_uid': providerUid,
      'auth_password': password,
      'auth_email': authEmail,
      'auth_display_name': displayName,
      'auth_last_name': lastName,
      'auth_first_name': firstName,
      'auth_first_name_kana': firstNameKata,
      'auth_last_name_kana': lastNameKata,
      'auth_phone_no': phone,
      'auth_zipcode': zipcode,
      'auth_pref': pref,
      'auth_addr1': addr1,
      'auth_addr2': addr2,
      'auth_profile_url': profileUrl,
      'auth_website_url': websiteUrl,
      'auth_image_url': imageUrl,
      'auth_regist': registerDate,
      'auth_phone_token': phoneToken,
      'auth_unregist': unregist,
      'active': active
    };
  }
}
