import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            // Circular Profile Picture
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/profile_picture.jpg'), // Add your image to assets
              ),
            ),
            SizedBox(height: 20),
            // Name
            Center(
              child: Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            // Email
            Center(
              child: Text(
                'johndoe@example.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),SizedBox(height: 2),
            /*Text('First Name',
                       style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromRGBO(56, 75, 112, 1),)),
            SizedBox(height: 20),*/
            // Additional Information
            Column(
              children: [
                // First Name and Last Name
                Row( 
                  children: [
                    
                  //SizedBox(height: 80),
                    Expanded(
                      child: RectangularField(
                       label: 'First Name',
                        value: 'Jane',
                  
                        
                      ),
                    ),
                    SizedBox(width: 16),

                    
                    Expanded(
                      child: RectangularField(
                       label: 'Last Name',
                        value: 'Smith',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // National ID
                RectangularField(
                 label: 'National ID',
                  value: '2000750515',
                ),
                SizedBox(height: 20),
                // Phone Number
                RectangularField(
                label: 'Phone Number',
                  value: '+1 234 567 890',
                ),
                SizedBox(height: 20),
                // Blood Type and Role
                Row(
                  children: [
                    Expanded(
                      child: RectangularField(
                      label: 'Blood Type',
                        value: 'O+',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: RectangularField(
                      label: 'Role',
                        value: 'Individual',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Address
                RectangularField(
                label: 'Address',
                  value: '123 Main St, New York, USA',
                   
                ),
                SizedBox(height: 20),
                // Edit and Remove Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Edit action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(56, 75, 112, 1),
                        minimumSize: Size(150,36),
                      ),
                      child: Text('Edit',style:TextStyle(color: Color.fromRGBO(252, 250, 238, 1)),),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Remove action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(148, 0, 31, 1),
                        minimumSize: Size(150,36),
                        
                      ),
                      child: Text('Remove',style:TextStyle(color: Color.fromRGBO(252, 250, 238, 1))
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget for Rectangular Fields
class RectangularField extends StatelessWidget {
  final String label;
  final String value;

  const RectangularField({
   required this.label,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(45, 37, 95, 255).withOpacity(0.2), // Light blue background
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: const Color.fromRGBO(56, 75, 112, 1),
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              
              color: const Color.fromRGBO(80, 118, 135, 1),
            ),
          ),
        ],
      ),
    );
  }
}