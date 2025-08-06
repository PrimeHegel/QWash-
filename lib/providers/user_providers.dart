import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qwash/model/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _firebaseUser;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  bool get isLoggedIn => _firebaseUser != null;

  // Fungsi untuk login
  Future<void> login(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _firebaseUser = userCredential.user;

      if (_firebaseUser != null) {
        await _fetchUserModel(_firebaseUser!.uid);
      }

      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  // Fungsi untuk register
  Future<void> register(String name, String email, String password, String room,
      {String role = "user"}) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _firebaseUser = userCredential.user;

      if (_firebaseUser != null) {
        // Simpan data ke Firestore, termasuk role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .set({
          'name': name.trim(),
          'email': email.trim(),
          'room': room.trim(),
          'role': role, // simpan role
        });

        _userModel = UserModel(
          uid: _firebaseUser!.uid,
          name: name,
          email: email,
          room: room,
          role: role, // simpan di model
        );

        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  // Ambil data user dari Firestore
  Future<void> _fetchUserModel(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = doc.data();
      if (data != null) {
        _userModel = UserModel.fromMap(data, uid);
      }
    } catch (e) {
      throw e;
    }
  }

  // Fungsi untuk logout
  Future<void> logout() async {
    await _auth.signOut();
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }
}
