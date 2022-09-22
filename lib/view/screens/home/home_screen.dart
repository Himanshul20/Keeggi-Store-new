import 'package:sixam_mart_store/controller/auth_controller.dart';
import 'package:sixam_mart_store/controller/notification_controller.dart';
import 'package:sixam_mart_store/controller/order_controller.dart';
import 'package:sixam_mart_store/controller/splash_controller.dart';
import 'package:sixam_mart_store/data/model/response/order_model.dart';
import 'package:sixam_mart_store/helper/price_converter.dart';
import 'package:sixam_mart_store/helper/route_helper.dart';
import 'package:sixam_mart_store/util/app_constants.dart';
import 'package:sixam_mart_store/util/dimensions.dart';
import 'package:sixam_mart_store/util/images.dart';
import 'package:sixam_mart_store/util/styles.dart';
import 'package:sixam_mart_store/view/base/confirmation_dialog.dart';
import 'package:sixam_mart_store/view/base/order_shimmer.dart';
import 'package:sixam_mart_store/view/base/order_widget.dart';
import 'package:sixam_mart_store/view/screens/home/widget/order_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool container_show=false;
  bool store_status_toogle=false;

  String store_id;


  Future<void> _loadData() async {
    await Get.find<AuthController>().getProfile();
    await Get.find<OrderController>().getCurrentOrders();
    await Get.find<NotificationController>().getNotificationList();
  }

  @override
  void initState() {

    Get.find<AuthController>().tooglestatusupdate(Get.find<AuthController>().profileModel.stores[0].id.toString());
    container_show = false;
    Get.find<AuthController>().temp_store_status=false;
    Get.find<AuthController>().temp_store_form=false;



    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _loadData();

    return Scaffold(

      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        leading: Padding(
          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
          child: Image.asset(Images.logo, height: 30, width: 30),
        ),
        titleSpacing: 0, elevation: 0,
        title: Text(AppConstants.APP_NAME, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(
          color: Theme.of(context).textTheme.bodyText1.color, fontSize: Dimensions.FONT_SIZE_DEFAULT,
        )),
        actions: [IconButton(
          icon: GetBuilder<NotificationController>(builder: (notificationController) {
            bool _hasNewNotification = false;
            if(notificationController.notificationList != null) {
              _hasNewNotification = notificationController.notificationList.length
                  != notificationController.getSeenNotificationCount();
            }
            return Stack(children: [
              Icon(Icons.notifications, size: 25, color: Theme.of(context).textTheme.bodyText1.color),
              _hasNewNotification ? Positioned(top: 0, right: 0, child: Container(
                height: 10, width: 10, decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, shape: BoxShape.circle,
                border: Border.all(width: 1, color: Theme.of(context).cardColor),
              ),
              )) : SizedBox(),
            ]);
          }),
          onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
        )],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(children: [

            GetBuilder<AuthController>(builder: (authController) {
              store_id=authController.profileModel.stores[0].id.toString() ;
              return Column(children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 200], spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      Get.find<SplashController>().configModel.moduleConfig.module.showRestaurantText
                          ? 'restaurant_temporarily_closed'.tr : 'store_temporarily_closed'.tr, style: robotoMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    authController.profileModel != null ? Switch(
                      value: !authController.profileModel.stores[0].active,
                      activeColor: Theme.of(context).primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool isActive) {


                        bool _showRestaurantText = Get.find<SplashController>().configModel.moduleConfig.module.showRestaurantText;
                        Get.dialog(ConfirmationDialog(
                          icon: Images.warning,
                          description: isActive ? _showRestaurantText ? 'are_you_sure_to_close_restaurant'.tr
                              : 'are_you_sure_to_close_store'.tr : _showRestaurantText ? 'are_you_sure_to_open_restaurant'.tr
                              : 'are_you_sure_to_open_store'.tr,
                          onYesPressed: () {
                        Get.back();
                        authController.toggleStoreClosedStatus();
                          },
                        ));
                      },
                    ) : Shimmer(duration: Duration(seconds: 2), child: Container(height: 30, width: 50, color: Colors.grey[300])),
                  ]),
                ),
                Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 200], spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      'Store Temporarily Closed by Date'.tr, style: robotoMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    authController.profileModel != null ? Switch(
                      value: authController.temp_store_status,
                      activeColor: Theme.of(context).primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool isActive) {

                        setState(() {
                          // container_show=!container_show;
                          print("hello ${container_show}");
                          authController.temp_store_status=isActive;
                          authController.temp_store_form=authController.temp_store_status;
                          if(!isActive){
                            authController.toggleStoreClosedStatusFTD(store_id,authController.fromdate.text,authController.todate.text,0);

                          }


                        });

                      },
                    ) : Shimmer(duration: Duration(seconds: 2), child: Container(height: 30, width: 50, color: Colors.grey[300])),
                  ]),
                ),
                authController.temp_store_form==true?Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 200], spreadRadius: 1, blurRadius: 5)],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Container(

                          child: Center(
                              child: TextField(

                                controller: authController.fromdate,
                                //editing controller of this TextField
                                decoration: InputDecoration(
                                    icon: Icon(Icons.calendar_today), //icon of text field
                                    labelText: "From Date" //label text of field
                                ),
                                readOnly: true,
                                //set it true, so that user will not able to edit text
                                onTap: () async {
                                  DateTime pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1950),
                                      //DateTime.now() - not to allow to choose before today.
                                      lastDate: DateTime(2100));

                                  if (pickedDate != null) {
                                    print(
                                        pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                                    String formattedDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                                    print(
                                        formattedDate); //formatted date output using intl package =>  2021-03-16
                                    setState(() {
                                      authController.fromdate.text =
                                          formattedDate; //set output date to TextField value.
                                    });
                                  } else {}
                                },
                              ))),
                    ),
                    Expanded(
                      child: Container(

                          child: Center(
                              child: TextField(

                                controller: authController.todate,
                                //editing controller of this TextField
                                decoration: InputDecoration(
                                    icon: Icon(Icons.calendar_today), //icon of text field
                                    labelText: "From Date" //label text of field
                                ),
                                readOnly: true,
                                //set it true, so that user will not able to edit text
                                onTap: () async {
                                  DateTime pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1950),
                                      //DateTime.now() - not to allow to choose before today.
                                      lastDate: DateTime(2100));

                                  if (pickedDate != null) {
                                    print(
                                        pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
                                    String formattedDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                                    print(
                                        formattedDate); //formatted date output using intl package =>  2021-03-16
                                    setState(() {
                                      authController.todate.text =
                                          formattedDate; //set output date to TextField value.
                                    });
                                  } else {}
                                },
                              ))),
                    ),
                    ElevatedButton(onPressed: ()=>{

                    Get.back(),
                    authController.toggleStoreClosedStatusFTD(store_id,authController.fromdate.text,authController.todate.text,1),
                      setState(() {
                        container_show = false;
                        store_status_toogle=false;
                        // authController.fromdate.text = ""; //set the initial value of text field
                        // authController.todate.text = "";
                      }),

                    }, child: Text("Submit"))
                  ]),
                ):Container(),
                SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                Container(
                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_LARGE),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image.asset(Images.wallet, width: 60, height: 60),
                      SizedBox(width: Dimensions.PADDING_SIZE_LARGE),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'today'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).cardColor),
                        ),
                        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                        Text(
                          authController.profileModel != null ? PriceConverter.convertPrice(authController.profileModel.todaysEarning) : '0',
                          style: robotoBold.copyWith(fontSize: 24, color: Theme.of(context).cardColor),
                        ),
                      ]),
                    ]),
                    SizedBox(height: 30),
                    Row(children: [
                      Expanded(child: Column(children: [
                        Text(
                          'this_week'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).cardColor),
                        ),
                        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                        Text(
                          authController.profileModel != null ? PriceConverter.convertPrice(authController.profileModel.thisWeekEarning) : '0',
                          style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE, color: Theme.of(context).cardColor),
                        ),
                      ])),
                      Container(height: 30, width: 1, color: Theme.of(context).cardColor),
                      Expanded(child: Column(children: [
                        Text(
                          'this_month'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).cardColor),
                        ),
                        SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                        Text(
                          authController.profileModel != null ? PriceConverter.convertPrice(authController.profileModel.thisMonthEarning) : '0',
                          style: robotoMedium.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE, color: Theme.of(context).cardColor),
                        ),
                      ])),
                    ]),
                  ]),
                ),
              ]);
            }),
            SizedBox(height: Dimensions.PADDING_SIZE_LARGE),

            GetBuilder<OrderController>(builder: (orderController) {
              List<OrderModel> _orderList = [];
              List<OrderModel> _porderList = [];
              int temporder = orderController.runningOrders[0].orderList.length;

              if(orderController.runningOrders != null) {
                _orderList = orderController.runningOrders[orderController.orderIndex].orderList;
                _porderList = orderController.runningOrders[0].orderList;
              }

              return Column(children: [

                orderController.runningOrders != null ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor, width: 1),
                    borderRadius: BorderRadius.circular(Dimensions.RADIUS_SMALL),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: orderController.runningOrders.length,
                    itemBuilder: (context, index) {
                      return OrderButton(
                        title: orderController.runningOrders[index].status.tr, index: index,
                        orderController: orderController, fromHistory: false,
                      );
                    },
                  ),
                ) : SizedBox(),

                orderController.runningOrders != null ? InkWell(
                  onTap: () => orderController.toggleCampaignOnly(),
                  child: Row(children: [
                    Checkbox(
                      activeColor: Theme.of(context).primaryColor,
                      value: orderController.campaignOnly,
                      onChanged: (isActive) => orderController.toggleCampaignOnly(),
                    ),
                    Text(
                      'campaign_order'.tr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).disabledColor),
                    ),
                  ]),
                ) : SizedBox(),

                orderController.runningOrders != null ? _orderList.length > 0 ? ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _orderList.length,
                  itemBuilder: (context, index) {
                    return OrderWidget(orderModel: _orderList[index], hasDivider: index != _orderList.length-1, isRunning: true);
                  },
                ) : Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(child: Text('no_order_found'.tr)),
                ) : ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return OrderShimmer(isEnabled: orderController.runningOrders == null);
                  },
                ),

              ]);
            }),

          ]),
        ),
      ),

    );
  }
}

