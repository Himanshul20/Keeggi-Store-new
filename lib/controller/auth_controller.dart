import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:sixam_mart_store/controller/splash_controller.dart';
import 'package:sixam_mart_store/data/api/api_checker.dart';
import 'package:sixam_mart_store/data/model/response/profile_model.dart';
import 'package:sixam_mart_store/data/model/response/response_model.dart';
import 'package:sixam_mart_store/data/repository/auth_repo.dart';
import 'package:sixam_mart_store/helper/network_info.dart';
import 'package:sixam_mart_store/view/base/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AuthController extends GetxController implements GetxService {
  final AuthRepo authRepo;

  AuthController({@required this.authRepo}) {
    _notification = authRepo.isNotificationActive();
  }

  bool _isLoading = false;
  bool _notification = true;
  ProfileModel _profileModel;
  Store _Storestatus;
  Uint8List _pickedFile;
  TextEditingController fromdate = TextEditingController();
  TextEditingController todate = TextEditingController();
  bool get isLoading => _isLoading;

  bool get notification => _notification;
  bool temp_store_status = false;
  bool temp_store_form = false;

  ProfileModel get profileModel => _profileModel;

  Uint8List get pickedFile => _pickedFile;
  String tempStoreMessageStatus(String msg){


  }
  Future<ResponseModel> login(String email, String password) async {
    _isLoading = true;
    update();
    Response response = await authRepo.login(email, password);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      authRepo.saveUserToken(
          response.body['token'], response.body['zone_wise_topic']);
      await authRepo.updateToken();
      responseModel = ResponseModel(true, 'successful');
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> getProfile() async {
    Response response = await authRepo.getProfileInfo();
    if (response.statusCode == 200) {
      _profileModel = ProfileModel.fromJson(response.body);
      Get.find<SplashController>().setModule(_profileModel.stores[0].module.id,
          _profileModel.stores[0].module.moduleType);
      authRepo.updateHeader(_profileModel.stores[0].module.id);
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<bool> updateUserInfo(
      ProfileModel updateUserModel, String token) async {
    _isLoading = true;
    update();
    Response response =
        await authRepo.updateProfile(updateUserModel, _pickedFile, token);
    _isLoading = false;
    bool _isSuccess;
    if (response.statusCode == 200) {
      _profileModel = updateUserModel;
      showCustomSnackBar('profile_updated_successfully'.tr, isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  void pickImage() async {
    XFile _picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (_picked != null) {
      _pickedFile = await NetworkInfo.compressImage(_picked);
    }
    update();
  }

  Future<bool> changePassword(
      ProfileModel updatedUserModel, String password) async {
    _isLoading = true;
    update();
    bool _isSuccess;
    Response response =
        await authRepo.changePassword(updatedUserModel, password);
    _isLoading = false;
    if (response.statusCode == 200) {
      Get.back();
      showCustomSnackBar('password_updated_successfully'.tr, isError: false);
      _isSuccess = true;
    } else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    update();
    return _isSuccess;
  }

  Future<ResponseModel> forgetPassword(String email) async {
    _isLoading = true;
    update();
    Response response = await authRepo.forgetPassword(email);

    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> updateToken() async {
    await authRepo.updateToken();
  }

  Future<ResponseModel> verifyToken(String email) async {
    _isLoading = true;
    update();
    Response response = await authRepo.verifyToken(email, _verificationCode);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> resetPassword(String resetToken, String email,
      String password, String confirmPassword) async {
    _isLoading = true;
    update();
    Response response = await authRepo.resetPassword(
        resetToken, email, password, confirmPassword);
    ResponseModel responseModel;
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, response.body["message"]);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  String _verificationCode = '';

  String get verificationCode => _verificationCode;

  void updateVerificationCode(String query) {
    _verificationCode = query;
    update();
  }

  bool _isActiveRememberMe = false;

  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  bool isLoggedIn() {
    return authRepo.isLoggedIn();
  }

  Future<bool> clearSharedData() async {
    Get.find<SplashController>().setModule(null, null);
    return await authRepo.clearSharedData();
  }

  void saveUserNumberAndPassword(String number, String password) {
    authRepo.saveUserNumberAndPassword(number, password);
  }

  String getUserNumber() {
    return authRepo.getUserNumber() ?? "";
  }

  String getUserPassword() {
    return authRepo.getUserPassword() ?? "";
  }

  Future<bool> clearUserNumberAndPassword() async {
    return authRepo.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authRepo.getUserToken();
  }

  bool setNotificationActive(bool isActive) {
    _notification = isActive;
    authRepo.setNotificationActive(isActive);
    update();
    return _notification;
  }

  void initData() {
    _pickedFile = null;
  }

  Future<void> toggleStoreClosedStatus(
   ) async {
    Response response = await authRepo.toggleStoreClosedStatus();
    if (response.statusCode == 200) {
      print("toggleStoreClosedStatus ${response.bodyString}");


      getProfile();
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }
  Future<void> toggleStoreClosedStatusFTD(
      String store_id,
      String fromdate,
      String todate,
      int status) async {
    Response response = await authRepo.toggleStoreClosedStatusFTD(
        store_id, fromdate, todate, status);
    if (response.statusCode == 200) {
      print("toggleStoreClosedStatus ${response.bodyString}");
      var message = jsonDecode(response.bodyString.toString());

      showCustomSnackBar(message["message"], isError: false);

      // if (message.contains("0")&&false) {
      //   showCustomSnackBar("Store open Successfully", isError: false);
      // } else {
      //   showCustomSnackBar("Store Closed Successfully", isError: false);
      // }
      getProfile();
    } else {
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<fetchToogleStatus> tooglestatusupdate(String store_id) async {

    String response = await authRepo.toggleStoreStatus(store_id);
    List<dynamic> list = jsonDecode(response);
    fetchToogleStatus model = fetchToogleStatus.fromJson(list[0]);
    temp_store_status= model.tempCloseBydateStatus=="1";
    temp_store_form=temp_store_status;
    fromdate.text=model.closeFrom.toString();
    todate.text=model.closeTo.toString();
    print(model);
    update();

    return model;


  }

}


class fetchToogleStatus {
  String id;
  String tempCloseBydateStatus;
  String closeFrom;
  String closeTo;

  fetchToogleStatus(
      {this.id, this.tempCloseBydateStatus, this.closeFrom, this.closeTo});

  fetchToogleStatus.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tempCloseBydateStatus = json['temp_close_bydate_status'];
    closeFrom = json['close_from'];
    closeTo = json['close_to'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['temp_close_bydate_status'] = this.tempCloseBydateStatus;
    data['close_from'] = this.closeFrom;
    data['close_to'] = this.closeTo;
    return data;
  }
}