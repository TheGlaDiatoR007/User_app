import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationList extends StatefulWidget {
  static const String routeName = '/notificationList';

  const NotificationList({Key? key}) : super(key: key);

  @override
  _NotificationListState createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  bool _isSearching = false;
  String _searchValue = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('/Notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final notificationDocs = snapshot.data!.docs;

                // Filter notificationDocs based on search value
                final filteredDocs = notificationDocs.where((doc) {
                  final notificationData = doc.data() as Map<String, dynamic>?;
                  final title = notificationData?['title'] as String?;

                  if (title == null) {
                    return false;
                  }

                  final titleLowerCase = title.toLowerCase();
                  final searchValueLowerCase = _searchValue.toLowerCase();

                  return titleLowerCase.contains(searchValueLowerCase);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final notificationData =
                    filteredDocs[index].data() as Map<String, dynamic>?;
                    final title = notificationData?['title'];
                    final timestamp = notificationData?['timestamp'];
                    final loginId = notificationData?['loginId'];
                    final name = notificationData?['name'];
                    final role = notificationData?['role'];
                    final content = notificationData?['content'];
                    final pdfUrl = notificationData?['pdfUrl'];

                    // Convert timestamp to DateTime
                    final dateTime = (timestamp as Timestamp).toDate();
                    final formattedDate = DateFormat.yMd().format(dateTime);
                    final time = DateFormat.jm().format(dateTime);

                    return Card(
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate ?? '',
                              style:
                              TextStyle(fontSize: 14.0, color: Colors.grey),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              time ?? '',
                              style:
                              TextStyle(fontSize: 14.0, color: Colors.grey),
                            ),
                            SizedBox(height: 8.0),
                            RichText(
                              text: TextSpan(
                                text: title ?? '',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: _getHighlightedTextColor(title),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: null, // Remove the trailing icon
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sent by:',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Name: ${name ?? 'Unknown'}',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                                Text(
                                  'Role: ${role ?? 'Unknown'}',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                                SizedBox(height: 16.0), // Add spacing
                                Text(
                                  'Content:',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  content ?? '',
                                  style: TextStyle(fontSize: 14.0),
                                ),
                                SizedBox(height: 16.0), // Add spacing
                                Text(
                                  'PDF URL:',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4.0),
                                GestureDetector(
                                  onTap: () {
                                    if (pdfUrl != null) {
                                      launch(pdfUrl);
                                    }
                                  },
                                  child: Text(
                                    pdfUrl != null ? pdfUrl : 'None',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchValue = '';
              });
            },
            icon: Icon(Icons.clear),
          ),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchValue = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHighlightedTextColor(String? title) {
    if (_searchValue.isEmpty || title == null) {
      return Colors.black;
    }

    final searchValueLowerCase = _searchValue.toLowerCase();
    final titleLowerCase = title.toLowerCase();

    if (titleLowerCase.contains(searchValueLowerCase)) {
      final startIndex = titleLowerCase.indexOf(searchValueLowerCase);
      final endIndex = startIndex + searchValueLowerCase.length;
      return Colors.red;
    }

    return Colors.black;
  }

  Future<void> _updateUserTimestamp() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userEmail = currentUser.email;
      final userRef = FirebaseFirestore.instance.collection('Users');
      final userDocs = await userRef.where('email', isEqualTo: userEmail).get();
      final userDoc = userDocs.docs.first;
      final userId = userDoc.id;
      await userRef.doc(userId).update({'timestamp': DateTime.now()});
    }
  }
}
prepare the BTech KTU S7 syllabus document in HTML , with internal links for navigation