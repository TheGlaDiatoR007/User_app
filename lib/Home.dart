import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/main.dart';
import 'package:user_app/profile_edit.dart';
import 'package:user_app/employee_profiles.dart';
import 'package:user_app/notification_list.dart';
import 'package:user_app/tax_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _fetchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final userProfile = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userProfile?.name ?? ''),
                  accountEmail: Text(userProfile?.email ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: userProfile?.profileImageUrl != null
                        ? NetworkImage('${userProfile!.profileImageUrl}?timestamp=${DateTime.now().millisecondsSinceEpoch}')
                        : AssetImage('assets/images/profile.png') as ImageProvider<Object>?,
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Name'),
                  subtitle: Text(userProfile?.name ?? ''),
                ),
                ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Email'),
                  subtitle: Text(userProfile?.email ?? ''),
                ),
                ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Phone Number'),
                  subtitle: Text(userProfile?.phoneNumber ?? ''),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Profile'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEdit(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      '${userProfile?.name ?? 'User'}',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 36.0),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2, // Number of columns in the grid
                  crossAxisSpacing: 16.0, // Spacing between columns
                  mainAxisSpacing: 16.0, // Spacing between rows
                  children: [
                    _buildCard(
                      title: 'EmployeeStatus',
                      iconPath: 'assets/icons/employee.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmployeeProfiles(),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      title: 'Notifications',
                      iconPath: 'assets/icons/noti.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationList(),
                          ),
                        );
                      },
                    ),
                    _buildCard(
                      title: 'TaxMoney',
                      iconPath: 'assets/icons/tax.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaxPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
    double height = 180.0, // Default height is set to 200.0
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center align the content vertically
              children: [
                Image.asset(
                  iconPath,
                  width: 100.0, // Increase the width to make the icon bigger
                  height: 100.0, // Increase the height to make the icon bigger
                ),
                SizedBox(height: 8.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


Future<UserProfile> _fetchUserProfile() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final userEmail = currentUser.email;
    final userData = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userData.docs.isNotEmpty) {
      final userProfile = UserProfile.fromSnapshot(userData.docs.first);
      return userProfile;
    }
  }

  throw Exception('User not found');
}

class UserProfile {
  final String name;
  final String email;
  final String? profileImageUrl;
  final String phoneNumber;

  UserProfile({
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.phoneNumber,
  });

  factory UserProfile.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserProfile(
      name: data['name'],
      email: data['email'],
      profileImageUrl: data['imageUrl'],
      phoneNumber: data['phoneNumber'],
    );
  }
}
