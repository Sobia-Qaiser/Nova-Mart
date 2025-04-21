import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

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

  @override
  void initState() {
    super.initState();
    fetchExistingBanners();
  }

  void fetchExistingBanners() async {
    EasyLoading.show(status: 'Loading...'); // Show loading indicator
    DatabaseReference ref = _database.ref("banners");
    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> banners = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          existingBanners = banners.entries.map((entry) {
            return {
              'key': entry.key, // Store the Firebase key for deletion
              'image': entry.value['image'].toString(),
            };
          }).toList();
        });
      }
      EasyLoading.dismiss(); // Hide loading indicator
    }).catchError((e) {
      EasyLoading.dismiss(); // Hide loading indicator on error
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
    EasyLoading.show(status: 'Uploading...', maskType: EasyLoadingMaskType.black);
    if (image == null) {
      EasyLoading.showError('Please select an image');
      return;
    }

    try {
      String? imageUrl = await uploadBannerToStorage(image);
      if (imageUrl == null) {
        EasyLoading.showError('Failed to upload image');
        return;
      }

      DatabaseReference ref = _database.ref("banners").push();
      await ref.set({'image': imageUrl});
      EasyLoading.showSuccess('Upload Complete');
      print("Data saved in Realtime Database");

      // Clear the image and refresh the list
      setState(() {
        image = null;
        fileName = null;
      });

      // Refresh the list of banners
      fetchExistingBanners();
    } catch (e) {
      EasyLoading.showError('Error: $e');
      print("Error uploading to database: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }

  void cancelImageSelection() {
    setState(() {
      image = null;
      fileName = null;
    });
  }

  // Function to delete a banner
  void deleteBanner(String key, String imageUrl) async {
    EasyLoading.show(status: 'Deleting...', maskType: EasyLoadingMaskType.black);

    try {
      // Delete from Firebase Realtime Database
      await _database.ref("banners").child(key).remove();

      // Delete from Firebase Storage
      Reference ref = storage.refFromURL(imageUrl);
      await ref.delete();

      EasyLoading.showSuccess('Banner Deleted');
      print("Banner deleted successfully");

      // Refresh the list of banners
      fetchExistingBanners();
    } catch (e) {
      EasyLoading.showError('Error: $e');
      print("Error deleting banner: $e");
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Banners',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Lora',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFF4A49),
        iconTheme: IconThemeData(
          color: Colors.white, // Set the back icon color to white
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              existingBanners.isEmpty
                  ? Center(
                child: Text(
                  "No Banners Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Lora',
                    color: Colors.grey.shade600,
                  ),
                ),
              )
              :ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: existingBanners.length,
                itemBuilder: (context, index) {
                  final bannerData = existingBanners[index];
                  return Card(
                    elevation: 0.3,
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Container(  // Added Container for background color
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
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Banner ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Lora',
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
                            onPressed: () {
                              deleteBanner(bannerData['key'], bannerData['image']);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),
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
                    title: Center(
                      child: Text(
                        'Upload Banner',
                        style: TextStyle(
                          fontFamily: 'Lora',
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
                              setState(() {}); // Rebuild the dialog to show the image
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
                                    Icon(
                                        Icons.add_a_photo,
                                        size: 30,
                                        color: Colors.grey.shade600),
                                    SizedBox(height: 5),
                                    Text(
                                      'Add Image',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontFamily: 'Lora',
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
                          SizedBox(height: 20),
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
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 16,
                                    fontFamily: 'Lora',
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  uploadToRealDatabase();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFF4A49),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Lora',
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
        backgroundColor: Color(0xFFFF4A49),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}