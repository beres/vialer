import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../../domain/repositories/contact.dart';
import '../../../../domain/repositories/permission.dart';
import '../../../../domain/entities/contact.dart';

import 'presenter.dart';

class ContactsController extends Controller {
  final ContactsPresenter _presenter;

  Completer _completer;

  List<Contact> contacts = [];

  String searchTerm = '';

  ContactsController(
    ContactRepository contactRepository,
    PermissionRepository permissionRepository,
  ) : _presenter = ContactsPresenter(contactRepository, permissionRepository);

  bool _hasPermission = true;

  bool get hasPermission => _hasPermission;

  @override
  void initController(GlobalKey<State<StatefulWidget>> key) {
    super.initController(key);

    getContacts();
  }

  void onSearch(String searchTerm) {
    this.searchTerm = searchTerm.isEmpty ? '' : searchTerm;
    refreshUI();
  }

  void getContacts() => _presenter.getContacts();

  void askPermission() => _presenter.askPermission();

  Future<void> updateContacts() {
    _completer = Completer();

    getContacts();

    return _completer.future;
  }

  void _onContactsUpdated(List<Contact> contacts) {
    this.contacts = contacts;

    refreshUI();

    _completer?.complete();
  }

  void _onNoPermission() {
    _hasPermission = false;
    refreshUI();
  }

  void _onPermissionGranted() {
    _hasPermission = true;
    getContacts();
  }

  @override
  void initListeners() {
    _presenter.contactsOnNext = _onContactsUpdated;
    _presenter.contactsOnNoPermission = _onNoPermission;
    _presenter.contactsOnPermissionGranted = _onPermissionGranted;
  }
}
