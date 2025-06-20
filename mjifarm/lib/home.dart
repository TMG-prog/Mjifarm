import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Login.dart';
import 'Farmer.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute <ProfileScreen>(builder: (context)=> ProfileScreen(
                appBar: AppBar(
                  title: const Text('User Profile'),
                ),
                  actions: [
                  SignedOutAction((context){
                  Navigator.of(context).pop();
                })],
                children: [
                  const Divider(),
                  Padding(
                  padding: const EdgeInsets.all(2),
                  child: AspectRatio(aspectRatio: 1, child: Image.asset('Mjifarms.jpg'),),
                  )
                ],
                
              ),),);
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [


            Text(
              'Welcome to MjiFarms!',
                style: Theme.of(context).textTheme.displaySmall,    
            ),
            
           SizedBox(
            width: 200,
            child:FloatingActionButton.extended(onPressed:()async{
             final user = FirebaseAuth.instance.currentUser;
                  if( user != null){
                    final name = user.displayName;
                    final uid= user.uid;
                    final email = user.email;
                    DatabaseReference ref = FirebaseDatabase.instance.ref("users/$uid");
                    await ref.set({
                      "name":name,
                      "email":email,
                       'userRole': ['farmer'],
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FarmerPage()),
                  );
            }
            , label: const Text("Join As a Farmer")
            )
           ),
//leave a space
            const SizedBox(height: 20,),
             SizedBox(
              width:200,
              child:FloatingActionButton.extended(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                label: Text("Join As an Expert"),
              ),



            ),
            const SignOutButton(),
          ],
        )
      ),
    );
  }
}