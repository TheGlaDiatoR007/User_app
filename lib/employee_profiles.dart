import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(EmployeeProfilesApp());
}

class EmployeeProfilesApp extends StatelessWidget {
  const EmployeeProfilesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Profiles',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EmployeeProfiles(),
    );
  }
}
class EmployeeProfiles extends StatelessWidget {
  const EmployeeProfiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Profiles'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Employee')
            .where('email', isNotEqualTo: null)
            .where('email', isNotEqualTo: '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          final employeeDocs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              itemCount: employeeDocs.length,
              itemBuilder: (context, index) {
                final employeeData = employeeDocs[index].data() as Map<String, dynamic>?;
                final profilePicUrl = employeeData?['profilePic'];
                final name = employeeData?['fullName'];
                final role = employeeData?['role'];
                final phoneNo= employeeData?['phoneNo'];
                final WorkingSchedule= employeeData?['WorkingSchedule'];
                final notes= employeeData?['notes'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeDetailsScreen(
                          index: index,
                          profilePic: profilePicUrl,
                          name: name,
                          role: role,
                          phoneNo: phoneNo,
                          WorkingSchedule: WorkingSchedule,
                          notes: notes,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(profilePicUrl ?? ''),
                          radius: 50.0,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          name ?? '',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          'Role: ${role ?? ''}',
                          style: TextStyle(fontSize: 14.0),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}



class EmployeeDetailsScreen extends StatelessWidget {
  final int index;
  final String? profilePic;
  final String? name;
  final String? role;
  final String? notes;
  final String? WorkingSchedule;
  final String? phoneNo;

  const EmployeeDetailsScreen({
    Key? key,
    required this.index,
    this.profilePic,
    this.name,
    this.role,
    this.notes,
    this.WorkingSchedule,
    this.phoneNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Details'),
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Hero(
              tag: 'employee_card_$index',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Card(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(profilePic ?? ''),
                              radius: 100.0,
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              name ?? '',
                              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              ' ${role ?? ''}',
                              style: TextStyle(fontSize: 20.0),
                            ),
                            Text(
                              'Note: ${notes ?? ''}',
                              style: TextStyle(fontSize: 20.0),
                            ),
                            Text(
                              'Work Schedule: ${WorkingSchedule ?? ''}',
                              style: TextStyle(fontSize: 20.0),
                            ),
                            Text(
                              'Phone Number: ${phoneNo ?? ''}',
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

