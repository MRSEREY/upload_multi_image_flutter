import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_absolute_path/flutter_absolute_path.dart';
import 'dart:async';

import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:upload_multi_image/services/image_compress_service.dart';
import 'package:http_parser/http_parser.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Asset> images = List<Asset>();

  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<List<File>> convertListAssetToListFile() async {
    List<File> files = List<File>();
    // images from galllery
    for (int i = 0; i < images.length; i++) {
      String imagePath = await FlutterAbsolutePath.getAbsolutePath(
        images[i].identifier,
      );
      File file = File(imagePath);
      files.add(file);
    }
    return files;
  }

  Future<FormData> _generateFormData() async {
    List<MultipartFile> multipartImageList = new List<MultipartFile>();

    List<File> files = await convertListAssetToListFile();

    for (var i = 0; i < files.length; i++) {
      ImageCompressService imageCompressService = ImageCompressService(
        file: files[i],
      );
      File afterCompress = await imageCompressService.exec();

      var pic = await MultipartFile.fromFile(
        afterCompress.path,
        filename: afterCompress.uri.toString(),
        contentType: MediaType("image", "jpg"),
      );
      multipartImageList.add(pic);
    }
    FormData formData = FormData.fromMap(
      {"package_photo": multipartImageList}, //package_photo is a key parameter
    );
    return formData;
  }

  _uploadImage() async {
    Dio dio = Dio();
    try {
      FormData formData = await _generateFormData();
      var reponse = await dio.post('your_api_endpoint', data: formData);
    } catch (e) {
      print('Error $e');
    }
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );

      await _uploadImage();
    } on Exception catch (e) {}
    if (!mounted) return;

    setState(() {
      images = resultList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            RaisedButton(
              child: Text("Pick images"),
              onPressed: loadAssets,
            ),
            Expanded(
              child: buildGridView(),
            )
          ],
        ),
      ),
    );
  }
}
