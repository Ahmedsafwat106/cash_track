import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'http://budgetapptry.runasp.net/api';

  void _log(String title, dynamic data) {
    print('=== $title ===');
    print(data);
  }

  Map<String, dynamic> _handle(http.Response r, String fallbackMsg,
      {String? url, dynamic body, String? token}) {
    _log("URL", url);
    _log("STATUS", r.statusCode);
    _log("RESPONSE", r.body);
    final text = r.body.trim();
    try {
      final decoded =
      text.isNotEmpty ? jsonDecode(text) : <String, dynamic>{};
      return {
        'statusCode': r.statusCode,
        'success': decoded['success'],
        'data': decoded['data'],
        'message': decoded['message'],
        'error': decoded['error'],
        'hasNextData': decoded['hasNextData'],
        'count': decoded['count'],
      };
    } catch (e) {
      if (e is Exception) rethrow;
      return {
        'statusCode': r.statusCode,
        'success': false,
        'error': fallbackMsg
      };
    }
  }


  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '$_base/Auth/Login';
    final body = {'Email': email.trim(), 'Password': password.trim()};
    final r = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return _handle(r, 'Login Failed', url: url, body: body);
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final url = '$_base/Auth/google-login';
    final body = {'idToken': idToken};
    final r = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return _handle(r, 'Google Login Failed', url: url);
  }

  Future<Map<String, dynamic>> register(String fullName, String email,
      String password, String confirmPassword, double budget) async {
    final url = '$_base/Auth/Register';
    final body = {
      'FullName': fullName.trim(),
      'Email': email.trim(),
      'Password': password.trim(),
      'ConfirmPassword': confirmPassword.trim(),
      'Budget': budget,
    };
    final r = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return _handle(r, 'Register Failed', url: url, body: body);
  }

  Future<Map<String, dynamic>> forgotPassword(
      String email, String clientUri) async {
    final url = '$_base/Auth/Forget-Password';
    final body = {'Email': email.trim(), 'ClientUri': clientUri};
    final r = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return _handle(r, 'Forgot Password Failed', url: url, body: body);
  }

  Future<Map<String, dynamic>> resetPassword(String email, String token,
      String password, String confirmPassword) async {
    final url = '$_base/Auth/Resetpassword';
    final body = {
      'Email': email.trim(),
      'Token': token.trim(),
      'Password': password.trim(),
      'ConfirmPassword': confirmPassword.trim(),
    };
    final r = await http.post(Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body));
    return _handle(r, 'Reset Failed', url: url, body: body);
  }

  Future<Map<String, dynamic>> resendConfirmationEmail(String email) async {
    final url =
        '$_base/Auth/resend-confirmation-email?email=${Uri.encodeComponent(email)}';
    final r = await http.get(Uri.parse(url));
    return _handle(r, 'Resend Failed', url: url);
  }


  Future<Map<String, dynamic>> getUserCurrentData(String token) async {
    final url = '$_base/Reports/user-current-data';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Reports Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getUserData(String token,
      {required int month, required int year}) async {
    final url = '$_base/Reports/user-data?month=$month&year=$year';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'User Data Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getBarChartData(String token) async {
    final url = '$_base/Reports/bar-chart';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Bar Chart Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getLineChartData(String token,
      {required int month, required int year}) async {
    final url = '$_base/Reports/line-chart?month=$month&year=$year';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Line Chart Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getMonthSummary(String token,
      {required int month, required int year}) async {
    final url = '$_base/Reports/month-summary?month=$month&year=$year';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Month Summary Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getTopCategories(String token) async {
    final url = '$_base/Reports/top-categories';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Top Categories Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getLatestTransactions(String token) async {
    final url = '$_base/Reports/lastest-transactions';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Latest Transactions Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getSpentCategories(String token,
      {int? month, int? year}) async {
    var url = '$_base/Reports/spent-categories';
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Spent Categories Failed', url: url, token: token);
  }


  Future<Map<String, dynamic>> getAllTransactions(String token, int page,
      {String? orderBy}) async {
    var url = '$_base/Transactions/all-transactions?pageNumber=$page';
    if (orderBy != null) url += '&orderBy=$orderBy';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Load Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> addExpense(String token,
      {required double amount,
        required String name,
        required String date,
        required String categoryName,
        required int paymentMethod,
        String? notes}) async {
    final url = '$_base/transactions/add-expense';
    final body = {
      'Amount': amount,
      'Name': name,
      'date': date,
      'CategoryName': categoryName,
      'PaymentMethod': paymentMethod,
      if (notes != null) 'Notes': notes,
    };
    final r = await http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Add Expense Failed', url: url, body: body, token: token);
  }

  Future<Map<String, dynamic>> updateExpense(String token,
      {required int expenseId,
        required double amount,
        required String categoryName,
        required String expenseName,
        String? date,
        String? notes}) async {
    final url = '$_base/transactions?expenseid=$expenseId';
    final body = {
      'Amount': amount,
      'CategoryName': categoryName,
      'ExpenseName': expenseName,
      if (date != null && date.isNotEmpty) 'Date': date,
      if (notes != null && notes.isNotEmpty) 'Notes': notes,
    };
    final r = await http.put(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Update Expense Failed',
        url: url, body: body, token: token);
  }

  Future<Map<String, dynamic>> deleteTransaction(String token, int id) async {
    final url = '$_base/transactions?id=$id';
    final r = await http.delete(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Delete Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> searchTransactions(
      String token, String q) async {
    final url =
        '$_base/transactions/transaction-search?item=${Uri.encodeComponent(q)}';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Search Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> getTransactionDetails(
      String token, int id) async {
    final url = '$_base/transactions/transaction-details?expenseId=$id';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Details Failed', url: url, token: token);
  }


  Future<Map<String, dynamic>> getAllCategories(
      String token, bool isExpense) async {
    final url = '$_base/category/all-categories?IsExpense=$isExpense';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 404) {
      return {'success': true, 'data': [], 'statusCode': 404};
    }
    return _handle(r, 'Categories Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> addCategory(String token,
      {required String name,
        required double budget,
        required bool isExpense}) async {
    final url = '$_base/Category/add-category';
    final body = {
      'CategoryName': name,
      'Budget': budget,
      'IsExpense': isExpense
    };
    final r = await http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Add Category Failed',
        url: url, body: body, token: token);
  }

  Future<Map<String, dynamic>> getAllIncomes(String token,
      {int page = 1}) async {
    final url = '$_base/income?pageNumber=$page';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Get Incomes Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> addIncome(String token,
      {required String categoryName,
        required String incomeName,
        required double amount,
        required String date,
        String? notes}) async {
    final url = '$_base/income/add-income';
    final body = {
      'CategoryName': categoryName,
      'IncomeName': incomeName,
      'Amount': amount,
      'date': date,
      if (notes != null) 'Notes': notes,
    };
    final r = await http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Add Income Failed', url: url, body: body, token: token);
  }

  Future<Map<String, dynamic>> deleteIncome(String token, int incomeId) async {
    final url = '$_base/Income?incomeid=$incomeId';
    final r = await http.delete(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Delete Income Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> updateIncome(String token,
      {required int incomeId,
        required String name,
        required String categoryName,
        required double amount}) async {
    final url = '$_base/Income?incomeId=$incomeId';
    final body = {
      'Name': name,
      'CategoryName': categoryName,
      'Amount': amount,
    };
    final r = await http.put(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Update Income Failed',
        url: url, body: body, token: token);
  }


  Future<Map<String, dynamic>> updateUserBalance(String token,
      {required double newBalance, required bool applyToCurrentMonth}) async {
    final url = '$_base/UserAccount';
    final body = {
      'NewBalance': newBalance,
      'ApplyToCurrentMonth': applyToCurrentMonth,
    };
    final r = await http.put(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));
    return _handle(r, 'Update Balance Failed',
        url: url, body: body, token: token);
  }


  Future<Map<String, dynamic>> getAllUploads(
      String token, int expenseId) async {
    final url = '$_base/Uploads/all-uploads?expenseId=$expenseId';
    final r = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Get Uploads Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> deleteUpload(
      String token, int uploadId) async {
    final url = '$_base/Uploads?uploadid=$uploadId';
    final r = await http.delete(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Delete Upload Failed', url: url, token: token);
  }

  Future<Map<String, dynamic>> uploadReceipt(
      String token, int expenseId, String filePath) async {
    final request =
    http.MultipartRequest('POST', Uri.parse('$_base/Uploads/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['ExpenseId'] = expenseId.toString();
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response, 'Upload Receipt Failed',
        url: '$_base/Uploads/upload');
  }

  Future<Map<String, dynamic>> saveDeviceId(String token,
      {required String deviceId}) async {
    final url =
        '$_base/UserAccount/save-deviceid?deviceid=${Uri.encodeComponent(deviceId)}';
    final r = await http.put(Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'});
    return _handle(r, 'Save Device ID Failed', url: url, token: token);
  }
}