import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class CategoryScreen extends StatefulWidget {
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final TextEditingController categoryController = TextEditingController();

  dynamic image;
  String? fileName;
  List<Map<String, String>> existingCategories = [];

  @override
  void initState() {
    super.initState();
    fetchExistingCategories();
  }

  void fetchExistingCategories() async {
    EasyLoading.show(status: 'Loading...'); // Show loading indicator
    DatabaseReference ref = _database.ref("categories");
    ref.once().then((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> categories = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          existingCategories = categories.entries.map((entry) {
            final value = entry.value as Map<dynamic, dynamic>;
            return {
              'key': entry.key.toString(),
              'name': value['category name'].toString(),
              'image': value['image'].toString(),
            };
          }).toList();
        });
      } else {
        setState(() {
          existingCategories = [];
        });
      }
      EasyLoading.dismiss(); // Hide loading indicator
    }).catchError((e) {
      EasyLoading.dismiss(); // Hide loading indicator on error
      print("Error fetching categories: $e");
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

  Future<String?> uploadCategoryImage(Uint8List image) async {
    if (fileName == null) return null;

    try {
      Reference ref = storage.ref().child('categories').child(fileName!);
      UploadTask uploadTask = ref.putData(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  String? validateCategoryName(String categoryName, {String? currentKey}) {
    if (categoryName.trim().isEmpty) {
      return "Category name is required.";
    }
    if (categoryName.trim().length < 3) {
      return "Category name must be at least 3 characters long.";
    }
    if (!RegExp(r'^[A-Za-z0-9 ]+$').hasMatch(categoryName)) {
      return "Category name can only contain letters, numbers, and spaces.";
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(categoryName)) {
      return "Category name must contain at least one letter.";
    }

    // Check if the category name already exists, excluding the current category being edited
    if (existingCategories.any((cat) =>
    cat['name']!.toLowerCase() == categoryName.toLowerCase() &&
        cat['key'] != currentKey)) {
      return "This category already exists.";
    }

    return null;
  }

  uploadCategoryToDatabase({String? key}) async {
    EasyLoading.show(status: 'Uploading...', maskType: EasyLoadingMaskType.black);

    String categoryName = categoryController.text.trim();
    String? validationMessage = validateCategoryName(categoryName, currentKey: key);

    if (validationMessage != null) {
      EasyLoading.showError(validationMessage);
      return;
    }

    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await uploadCategoryImage(image);
        if (imageUrl == null) {
          EasyLoading.showError('Failed to upload image');
          return;
        }
      } else if (key != null) {
        // If no new image is selected, keep the existing image URL
        imageUrl = existingCategories.firstWhere((cat) => cat['key'] == key)['image'];
      }

      if (imageUrl == null) {
        EasyLoading.showError('Please select an image');
        return;
      }

      DatabaseReference ref;
      if (key != null) {
        ref = _database.ref("categories").child(key);
      } else {
        ref = _database.ref("categories").push();
      }

      await ref.set({
        'category name': categoryName,
        'image': imageUrl,
      });

      EasyLoading.showSuccess('Upload Complete');

      // Refresh the list immediately
      fetchExistingCategories();

      clearForm();
    } catch (e) {
      EasyLoading.showError('Error: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  void clearForm() {
    setState(() {
      image = null;
      categoryController.clear();
    });
  }

  void deleteCategory(String key) async {
    try {
      await _database.ref("categories").child(key).remove();
      EasyLoading.showSuccess('Category Deleted');
      fetchExistingCategories();
    } catch (e) {
      EasyLoading.showError('Error: $e');
    }
  }

  void _showUploadDialog({Map<String, String>? category}) {
    if (category != null) {
      categoryController.text = category['name']!;
      setState(() {
        image = null; // Reset image to allow re-upload
      });
    }

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
                  category == null ? 'Upload Category' : 'Edit Category',
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
                          child: image == null && category == null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 30,
                                color: Colors.grey.shade600,
                              ),
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
                            child: image != null
                                ? Image.memory(image, fit: BoxFit.cover)
                                : Image.network(category!['image']!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6, // Adjust width here
                      child: TextFormField(
                        controller: categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontFamily: 'Lora',),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFFF4A49)),
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
                            clearForm();
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
                            uploadCategoryToDatabase(key: category?['key']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF4A49),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            category == null ? 'Save' : 'Update',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categories',
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              existingCategories.isEmpty
                  ? Center(
                child: Text(
                  "No Category Found",
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
                itemCount: existingCategories.length,
                itemBuilder: (context, index) {
                  final categoryData = existingCategories[index];
                  return Card(
                    elevation: 0.3,
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                                      categoryData['image']!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    categoryData['name']!,
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
                          child: Row(  // Changed from Column to Row
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                                onPressed: () {
                                  _showUploadDialog(category: categoryData);
                                },
                              ),
                              SizedBox(width: 1),  // Changed from height to width
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                                onPressed: () {
                                  deleteCategory(categoryData['key']!);
                                },
                              ),
                            ],
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
        onPressed: _showUploadDialog,
        backgroundColor: Color(0xFFFF4A49),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}