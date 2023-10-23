// A screen that allows users to take a picture using a given camera.
import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CaptureCropPictureScreen extends StatefulWidget {
  const CaptureCropPictureScreen({super.key});

  @override
  State<CaptureCropPictureScreen> createState() =>
      _CaptureCropPictureScreenState();
}

class _CaptureCropPictureScreenState extends State<CaptureCropPictureScreen> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  bool _isProcessing = false;
  bool _isDataReady = false;
  String _detectedText = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hand Digit Rec."),
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_isProcessing) {
      return _resultCard();
    }
    if (_croppedFile != null || _pickedFile != null) {
      return _imageCard();
    } else {
      return _uploaderCard();
    }
  }

  Widget _imageCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _image(),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _menu(),
        ],
      ),
    );
  }

  Future uploadImage(String filepath, String url) async {
    print("[LOG] in UploadImage Function");
    var request = http.MultipartRequest('POST', Uri.parse(url));
    // request.fields['image_name'] = filename;
    request.files.add(http.MultipartFile.fromBytes(
        'file', File(filepath).readAsBytesSync(),
        filename: filepath.split("/").last));
    var res = await request.send();
    var data = await res.stream.toBytes();
    var result = String.fromCharCodes(data);
    print("res: $result");
    return Future.value(jsonDecode(result)["value"]);
  }

  Widget _image() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (_croppedFile != null) {
      final path = _croppedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: Image.file(File(path)),
      );
    } else if (_pickedFile != null) {
      final path = _pickedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: Image.file(File(path)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () {
            _clear();
          },
          backgroundColor: const Color(0xFFEC6A5E),
          tooltip: 'Delete',
          child: const Icon(Icons.delete),
        ),
        if (_croppedFile == null || _pickedFile != null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () {
                _cropImage();
              },
              backgroundColor: const Color(0xFFE0BF4F),
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
          ),
        if (_pickedFile != null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: FloatingActionButton(
              onPressed: () {
                _processImage();
              },
              backgroundColor: const Color(0xFF61C554),
              tooltip: 'Process',
              child: const Icon(Icons.check),
            ),
          )
      ],
    );
  }

  Widget _uploaderCard() {
    return Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: SizedBox(
          width: 320.0,
          height: 300.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DottedBorder(
                    radius: const Radius.circular(12.0),
                    borderType: BorderType.RRect,
                    dashPattern: const [8, 4],
                    color: Theme.of(context).highlightColor.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Theme.of(context).highlightColor,
                            size: 80.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Upload an image to start',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: Theme.of(context).highlightColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.tealAccent)),
                      onPressed: () {
                        _captureImage();
                      },
                      child: const Text('Capture'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.tealAccent)),
                      onPressed: () {
                        _uploadImage();
                      },
                      child: const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard() {
    String url = "http://10.6.1.197:8000/upload_img/";
    String? filePath = "";
    if (_pickedFile != null) {
      filePath = _pickedFile?.path;
    }
    if (_croppedFile != null) {
      filePath = _croppedFile?.path;
    }
    return Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: SizedBox(
          width: 320.0,
          height: 300.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder(
                  future: uploadImage(filePath!, url),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) {
                      return Column(
                        children: [
                          const SpinKitDoubleBounce(
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Recognized Text will appear here !!!",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text("Something went wrong");
                    }
                    _detectedText=snapshot.data;
                    return SingleChildScrollView(
                      child: Text(
                        _detectedText,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Colors.white),
                      ),
                    );
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.tealAccent)),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _detectedText));
                      },
                      child: const Text('Copy'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                          MaterialStatePropertyAll(Colors.tealAccent)),
                      onPressed: () async {
                        _clear();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.tealAccent,
              activeControlsWidgetColor: Colors.tealAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          )
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  Future<void> _processImage() async {
    if (_pickedFile != null || _croppedFile != null) {
      String? filePath = "";
      if (_pickedFile != null) {
        filePath = _pickedFile?.path;
      }
      if (_croppedFile != null) {
        filePath = _croppedFile?.path;
      }
      if (_detectedText.isEmpty) {
        setState(() {
          _isProcessing = true;
        });
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  Future<void> _captureImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
      _isProcessing = false;
      _detectedText = "";
    });
  }
}