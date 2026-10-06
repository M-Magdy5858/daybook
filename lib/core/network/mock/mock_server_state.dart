class MockUser {
  MockUser(this.id, this.name, this.email, this.password);
  final String id, name, email, password;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'email': email};
}

class MockServerState {
  final users = <MockUser>[
    MockUser('1', 'Demo', 'demo@daybook.dev', 'password123'),
  ];
}
