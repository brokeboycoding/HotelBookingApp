import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'firebase_services.dart';

class AuthService {
  final FirebaseService _firebase = FirebaseService();

  // =========================
  // ✅ API thuần Việt (khuyên dùng)
  // =========================

  /// Đăng ký tài khoản
  Future<UserModel> dangKy({
    required String email,
    required String matKhau,
    required String hoTen,
    required UserRole vaiTro,
    String? soDienThoai,
  }) async {
    try {
      final emailSach = email.trim().toLowerCase();
      final matKhauSach = matKhau.trim();
      final hoTenSach = hoTen.trim();

      final userCredential = await _firebase.auth.createUserWithEmailAndPassword(
        email: emailSach,
        password: matKhauSach,
      );

      final uid = userCredential.user!.uid;

      // (Tuỳ chọn) set displayName trong FirebaseAuth
      await userCredential.user!.updateDisplayName(hoTenSach);

      final nguoiDungMoi = UserModel(
        uid: uid,
        email: emailSach,
        name: hoTenSach,
        phone: soDienThoai?.trim(),
        role: vaiTro,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firebase.usersCollection.doc(uid).set(nguoiDungMoi.toMap());
      return nguoiDungMoi;
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  /// Đăng nhập
  Future<UserModel?> dangNhap({
    required String email,
    required String matKhau,
  }) async {
    try {
      final emailSach = email.trim().toLowerCase();
      final matKhauSach = matKhau.trim();

      final userCredential = await _firebase.auth.signInWithEmailAndPassword(
        email: emailSach,
        password: matKhauSach,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) return null;

      final doc = await _firebase.usersCollection.doc(uid).get();

      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);

      // Kiểm tra bị khóa/vô hiệu hóa
      if (!user.isActive) {
        await _firebase.auth.signOut();
        throw 'Tài khoản đã bị vô hiệu hóa.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi: $e';
    }
  }

  /// Đăng xuất
  Future<void> dangXuat() async {
    try {
      await _firebase.auth.signOut();
    } catch (e) {
      throw 'Không thể đăng xuất: $e';
    }
  }

  /// Lấy thông tin người dùng hiện tại
  Future<UserModel?> layNguoiDungHienTai() async {
    try {
      final uid = _firebase.currentUserId;
      if (uid == null) return null;

      final doc = await _firebase.usersCollection.doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw 'Không thể lấy thông tin người dùng: $e';
    }
  }

  /// Theo dõi thông tin người dùng hiện tại (stream)
  Stream<UserModel?> theoDoiNguoiDungHienTai() {
    final uid = _firebase.currentUserId;
    if (uid == null) return Stream.value(null);

    return _firebase.usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> guiEmailDatLaiMatKhau(String email) async {
    try {
      await _firebase.auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Không thể gửi email đặt lại mật khẩu: $e';
    }
  }

  /// Cập nhật hồ sơ người dùng (Firestore)
  Future<void> capNhatHoSoNguoiDung({
    required String uid,
    String? hoTen,
    String? soDienThoai,
    String? duongDanAnhDaiDien,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (hoTen != null) updates['name'] = hoTen.trim();
      if (soDienThoai != null) updates['phone'] = soDienThoai.trim();
      if (duongDanAnhDaiDien != null) updates['avatarUrl'] = duongDanAnhDaiDien.trim();

      if (updates.isEmpty) return;

      await _firebase.usersCollection.doc(uid).update(updates);

      // (Tuỳ chọn) cập nhật displayName/photoURL trong FirebaseAuth
      final u = _firebase.currentUser;
      if (u != null && u.uid == uid) {
        if (hoTen != null) await u.updateDisplayName(hoTen.trim());
        if (duongDanAnhDaiDien != null) await u.updatePhotoURL(duongDanAnhDaiDien.trim());
      }
    } catch (e) {
      throw 'Không thể cập nhật thông tin: $e';
    }
  }

  /// Đổi mật khẩu (có xác thực lại)
  Future<void> doiMatKhau({
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    try {
      final user = _firebase.currentUser;
      if (user == null) throw 'Người dùng chưa đăng nhập.';

      final email = user.email;
      if (email == null || email.trim().isEmpty) {
        throw 'Tài khoản không có email để xác thực.';
      }

      final credential = EmailAuthProvider.credential(
        email: email.trim().toLowerCase(),
        password: matKhauHienTai.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(matKhauMoi.trim());
    } on FirebaseAuthException catch (e) {
      throw _xuLyLoiXacThuc(e);
    } catch (e) {
      throw 'Không thể đổi mật khẩu: $e';
    }
  }

  String _xuLyLoiXacThuc(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return 'Lỗi xác thực: [${e.code}] ${e.message ?? ''}'.trim();
    }
  }

  // =========================
  // ✅ GIỮ TÊN HÀM CŨ (đỡ sửa code chỗ khác)
  // =========================
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
  }) =>
      dangKy(email: email, matKhau: password, hoTen: name, vaiTro: role, soDienThoai: phone);

  Future<UserModel?> signIn({required String email, required String password}) =>
      dangNhap(email: email, matKhau: password);

  Future<void> signOut() => dangXuat();

  Future<UserModel?> getCurrentUserData() => layNguoiDungHienTai();

  Stream<UserModel?> streamCurrentUserData() => theoDoiNguoiDungHienTai();

  Future<void> resetPassword(String email) => guiEmailDatLaiMatKhau(email);

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
  }) =>
      capNhatHoSoNguoiDung(
        uid: uid,
        hoTen: name,
        soDienThoai: phone,
        duongDanAnhDaiDien: avatarUrl,
      );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      doiMatKhau(matKhauHienTai: currentPassword, matKhauMoi: newPassword);
}
