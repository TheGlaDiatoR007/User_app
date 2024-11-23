import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:user_app/Home.dart';

class ProfileEdit extends StatefulWidget {
  final String? userId;

  const ProfileEdit({Key? key, this.userId}) : super(key: key);

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _aadharNumberController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  File? _image;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadharNumberController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });

      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final storageRef =
        firebase_storage.FirebaseStorage.instance.ref().child('users/$userId/profile.jpg');

        final uploadTask = storageRef.putFile(_image!);
        final snapshot = await uploadTask;

        if (snapshot.state == firebase_storage.TaskState.success) {
          final imageUrl = await storageRef.getDownloadURL();
          setState(() {
            _imageUrl = imageUrl;
          });
        } else {
          print('Error uploading image: Upload task was not successful');
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userProfile = UserProfile.fromSnapshot(snapshot.docs.first);
        _nameController.text = userProfile.name;
        _aadharNumberController.text = userProfile.aadharNumber;
        _phoneNumberController.text = userProfile.phoneNumber;
        _addressController.text = userProfile.address;
        setState(() {
          _imageUrl = userProfile.imageUrl;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final email = FirebaseAuth.instance.currentUser?.email;

      if (email != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final documentSnapshot = querySnapshot.docs.first;
          await documentSnapshot.reference.update({
            'name': _nameController.text,
            'aadharNumber': _aadharNumberController.text,
            'phoneNumber': _phoneNumberController.text,
            'address': _addressController.text,
            'imageUrl': _imageUrl,
          });
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        ); // Return to the previous screen
      }
    } catch (e) {
      print('Error updating user profile: $e');
      // Handle the error or show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    if (_imageUrl != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_imageUrl!),
      );
    } else if (_image != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_image!),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.camera_alt, color: Colors.black),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () async {
                  await _pickImage();
                  setState(() {}); // Rebuild the widget to show the updated image
                },
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : _buildProfileImage(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _aadharNumberController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  hintText: 'Enter your Aadhar number',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter your address',
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
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
}

class UserProfile {
  final String name;
  final String aadharNumber;
  final String phoneNumber;
  final String address;
  final String? imageUrl;

  UserProfile({
    required this.name,
    required this.aadharNumber,
    required this.phoneNumber,
    required this.address,
    this.imageUrl,
  });

  factory UserProfile.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserProfile(
      name: data['name'] ?? '',
      aadharNumber: data['aadharNumber'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
}
