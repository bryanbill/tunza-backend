import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:tunza/models/user.dart';
import 'package:zero/zero.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Database {
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  PostgreSQLConnection? conn;

  Future<void> connect() async {
    print("Connecting to database...");
    conn = PostgreSQLConnection(
        meta.env['HOST'], int.parse(meta.env['PORT']), meta.env['DB'],
        username: meta.env['USER'], password: meta.env['PASS']);
    await conn!.open();
  }

  Future<void> disconnect() async {
    await conn!.close();
  }
}

mixin DbMixin {
  final Database _db = Database();
  PostgreSQLConnection? get conn => _db.conn;

  // helpers
  String hashPassword(String password) {
    var bytes = utf8.encode(password + meta.env['SALT']!);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String token(PostgreSQLResult result) {
    final user = User.fromPostgres(result.first);

    final jwt = JWT(
        {
          'id': user.id,
          'name': user.full_name,
          'email': user.email,
          'role': user.role,
        },
        issuer: 'tunza',
        subject: 'auth',
        header: {
          'typ': 'JWT',
        });

    return jwt.sign(SecretKey(
      meta.env['JWT_SECRET']!,
    ));
  }

  JWT verify(String token) =>
      JWT.verify(token, SecretKey(meta.env['JWT_SECRET']!));
}
