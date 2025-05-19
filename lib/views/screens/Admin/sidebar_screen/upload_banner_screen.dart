import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadBannerScreen extends StatefulWidget {
  @override
  State<UploadBannerScreen> createState() => _UploadBannerScreenState();
}

class _UploadBannerScreenState extends State<UploadBannerScreen> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  dynamic image;
  String? fileName;
  List<Map<String, dynamic>> existingBanners = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchExistingBanners();
  }

  void fetchExistingBanners() async {
    setState(() {
      isLoading = true;
    });

    DatabaseReference ref = _database.ref("banners");
    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> banners = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          existingBanners = banners.entries.map((entry) {
            return {
              'key': entry.key,
              'image': entry.value['image'].toString(),
            };
          }).toList();
        });
      }
      setState(() {
        isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching banners: $e");
    });
  }

  pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        image = result.files.first.bytes;
        fileName = result.files.first.name;
      });
    }
  }

  Future<String?> uploadBannerToStorage(Uint8List image) async {
    if (fileName == null) {
      print("File name is null, cannot upload.");
      return null;
    }

    try {
      Reference ref = storage.ref().child('banners').child(fileName!);
      UploadTask uploadTask = ref.putData(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  uploadToRealDatabase() async {
    setState(() {
      isLoading = true;
    });

    if (image == null) {
      Get.snackbar(
        "Error",
        "Please select an image",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String? imageUrl = await uploadBannerToStorage(image);
      if (imageUrl == null) {
        Get.snackbar(
          "Error",
          "Failed to upload image",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black,
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      DatabaseReference ref = _database.ref("banners").push();
      await ref.set({'image': imageUrl});
      Get.snackbar(
        "Success",
        "Image uploaded successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        shouldIconPulse: false,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        margin: const EdgeInsets.all(10),
      );

      setState(() {
        image = null;
        fileName = null;
        isLoading = false;
      });

      fetchExistingBanners();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Error uploading to database: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void cancelImageSelection() {
    setState(() {
      image = null;
      fileName = null;
    });
  }

  void deleteBanner(String key, String imageUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      await _database.ref("banners").child(key).remove();
      Reference ref = storage.refFromURL(imageUrl);
      await ref.delete();
      Get.snackbar(
        "Success",
        "Banner deleted successfully",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        shouldIconPulse: false,
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
        margin: const EdgeInsets.all(10),
      );

      fetchExistingBanners();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Error deleting banner: $e",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Banners',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF4A49),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF4A49)),
        ),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  existingBanners.isEmpty
                      ? Center(
                    child: Text(
                      "No Banners Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: existingBanners.length,
                    itemBuilder: (context, index) {
                      final bannerData = existingBanners[index];
                      return Card(
                        elevation: 0.3,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          bannerData['image']!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Banner ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 5,
                              child: IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                                onPressed: () => deleteBanner(bannerData['key'], bannerData['image']),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Center(
                      child: Text(
                        'Upload Banner',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await pickImage();
                              setState(() {});
                            },
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: image == null
                                    ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 30, color: Colors.grey.shade600),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Add Image',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                )
                                    : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(image, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  cancelImageSelection();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  uploadToRealDatabase();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4A49),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        backgroundColor: const Color(0xFFFF4A49),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}