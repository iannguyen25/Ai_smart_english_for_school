import 'dart:convert';
import 'dart:io';

import 'package:base_flutter_framework/core/models/user.dart';

import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

//cache file
class Shared {
  static Shared? instance;
  static Shared getInstance() {
    if (instance == null) {
      instance = new Shared();
    }
    return instance!;
  }

  String? version;

  UserModel? userModel;

  String publicToken = "";

  // List<Article>? niceArticleData = [];

  // Future<void> saveUser({required UserModel user}) async {
  //   await deleteUser();
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   this.userModel = user;
  //   await preferences.setString(
  //       "USER", jsonEncode(this.userModel));
  // }

  Future<void> getVersionCode() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  Future<bool> saveUser({required UserModel user}) async {
    await deleteUser();
    SharedPreferences preferences = await SharedPreferences.getInstance();

    userModel = user;
    await preferences.setString("USER", jsonEncode(this.userModel!.toJson()));
    print(userModel);
    return true;
  }

  Future<bool> deleteUser() async {
    // await FcmFirebase.getInstance()!.;

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove("USER");
    userModel = null;
    // await deleteNiceArticle();
    return true;
  }

  Future<UserModel?> getUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey("USER")) {
      userModel =
          UserModel.fromJson(jsonDecode(preferences.getString("USER")!));

      return userModel;
    }
    return null;
  }
}
