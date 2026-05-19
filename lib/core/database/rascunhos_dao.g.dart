// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rascunhos_dao.dart';

// ignore_for_file: type=lint
mixin _$RascunhosDaoMixin on DatabaseAccessor<AppDatabase> {
  $RascunhosTable get rascunhos => attachedDatabase.rascunhos;
  RascunhosDaoManager get managers => RascunhosDaoManager(this);
}

class RascunhosDaoManager {
  final _$RascunhosDaoMixin _db;
  RascunhosDaoManager(this._db);
  $$RascunhosTableTableManager get rascunhos =>
      $$RascunhosTableTableManager(_db.attachedDatabase, _db.rascunhos);
}
