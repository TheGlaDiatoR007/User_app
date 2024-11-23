import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuildingData {
  final String wardNo;
  final int buildingNo;
  final double tax;
  double fine;

  BuildingData({
    required this.wardNo,
    required this.buildingNo,
    required this.tax,
    required this.fine,
  });
}

class TaxPage extends StatefulWidget {
  const TaxPage({Key? key}) : super(key: key);

  @override
  _TaxPageState createState() => _TaxPageState();
}

class _TaxPageState extends State<TaxPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Page'),
        actions: [
          IconButton(
            onPressed: () => _showTextFieldPopup(context),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/tax.png'),
            const SizedBox(height: 20.0),
            Expanded(
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('Building').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    final buildingData = snapshot.data!.docs;
                    final List<BuildingData> dataList = [];

                    // Filter data based on the current login email
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      final currentUserEmail = currentUser.email;

                      for (var doc in buildingData) {
                        final Map<String, dynamic> data = doc.data();
                        final String email = data['email'] as String? ?? '';
                        if (email == currentUserEmail) {
                          final String wardNo = data['wardNo'] as String? ?? '';
                          final int buildingNo = data['buildingNo'] as int? ?? 0;
                          final dynamic taxValue = data['tax']; // Retrieve tax data

                          // Convert taxValue to double if it's a String
                          final double tax = taxValue is double ? taxValue : double.tryParse(taxValue.toString()) ?? 0.0;

                          // Fine amount will be initialized to 0.0, update it after fetching fine rate
                          final buildingDataObj = BuildingData(
                            wardNo: wardNo,
                            buildingNo: buildingNo,
                            tax: tax,
                            fine: 0.0,
                          );
                          dataList.add(buildingDataObj);
                        }
                      }
                    }

                    // Fetch the due date and fine rate
                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([fetchDueDate(), fetchFineRate()]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasData && snapshot.data != null) {
                          final DateTime dueDate = snapshot.data![0];

                          // Calculate the fine amount based on the difference between current date and due date
                          final DateTime currentDate = DateTime.now();
                          final int differenceInDays = currentDate.difference(dueDate).inDays;
                          final double fineRate = snapshot.data![1];
                          final double fineAmount = (differenceInDays / 30) * fineRate / 100;
                          final double fineAmountWithTwoDigits = double.parse(fineAmount.toStringAsFixed(2));

                          // Update the fine amount for each building data
                          for (int i = 0; i < dataList.length; i++) {
                            dataList[i].fine = fineAmountWithTwoDigits;
                          }

                          // Use 'dataList' to display the building details along with tax amount
                          return ListView.builder(
                            itemCount: dataList.length + 1, // Add 1 for the due date ListTile
                            itemBuilder: (context, index) {
                              if (index < dataList.length) {
                                final buildingData = dataList[index];
                                return ListTile(
                                  title: Text('Ward No: ${buildingData.wardNo}, Building No: ${buildingData.buildingNo}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tax Amount: ${buildingData.tax}'),
                                      Text('Fine Amount: ${fineAmountWithTwoDigits * buildingData.tax }'),
                                      Text('Total Amount: ${buildingData.tax + buildingData.fine * buildingData.tax}'),
                                    ],
                                  ),
                                );
                              } else {
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 2.0),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  margin: EdgeInsets.all(16.0),
                                  padding: EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text('Due Date: ${dueDate.toLocal()}'),
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    );
                  } else {
                    return const Text('No building data found');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to fetch the due date from Firestore
  Future<DateTime?> fetchDueDate() async {
    final snapshot = await FirebaseFirestore.instance.collection('TaxRate').doc('AhupZ06Ku222LJQAJZPj').get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final dynamic dueDateTimestamp = data['dueDate'];
      if (dueDateTimestamp != null) {
        return DateTime.fromMicrosecondsSinceEpoch(dueDateTimestamp.microsecondsSinceEpoch);
      }
    }
    return null;
  }

  // Function to fetch the fine rate from Firestore
  Future<double> fetchFineRate() async {
    final snapshot = await FirebaseFirestore.instance.collection('TaxRate').doc('AhupZ06Ku222LJQAJZPj').get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final dynamic fineRateValue = data['finePerDay'];
      return fineRateValue is double ? fineRateValue : double.tryParse(fineRateValue.toString()) ?? 0.0;
    }
    return 0.0;
  }

  // Function to show the text field popup for adding building details
  void _showTextFieldPopup(BuildContext context) async {
    final TextEditingController _wardNoController = TextEditingController();
    final TextEditingController _buildingNoController = TextEditingController();

    String? wardNoError;
    String? buildingNoError;

    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Building Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _wardNoController,
                    onChanged: (value) {
                      setState(() {
                        wardNoError = value.isEmpty ? 'Please enter Ward No' : null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Ward No',
                      errorText: wardNoError,
                    ),
                  ),
                  TextField(
                    controller: _buildingNoController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        buildingNoError = value.isEmpty ? 'Please enter Building No' : null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Building No',
                      errorText: buildingNoError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false when cancel button is pressed
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final String wardNo = _wardNoController.text;
                    final int buildingNo = int.tryParse(_buildingNoController.text) ?? 0;

                    // Validate if the fields are not empty
                    if (wardNo.isEmpty || buildingNo == 0) {
                      setState(() {
                        wardNoError = wardNo.isEmpty ? 'Please enter Ward No' : null;
                        buildingNoError = buildingNo == 0 ? 'Please enter Building No' : null;
                      });
                    } else {
                      // Save the data to the Building collection with the current login email
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        await FirebaseFirestore.instance.collection('Building').add({
                          'wardNo': wardNo,
                          'buildingNo': buildingNo,
                          'email': currentUser.email, // Add the current user's email to the data
                          'tax': 0.0, // Initialize tax to 0, update this value as per requirement
                        });
                      }

                      // Close the popup and return true
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // If the result is true (user saved the building details), reload the TaxPage
    if (result == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TaxPage()), // Push a new TaxPage on top of the current one
      );
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: TaxPage(),
  ));
}
