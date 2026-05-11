abstract class AppRoutes {
  // Auth
  static const login     = '/login';
  static const register  = '/register';

  // Onboarding
  static const welcome = '/';
  static const joinOrCreateHouse = '/join-or-create-house';
  static const joinHouse   = '/join-house';
  static const createHouse = '/create-house';
  static const houseCreatedSuccess = '/house-created-success';

  // Menu principal
  static const tasks    = '/tasks';
  static const cards    = '/cards';
  static const ranking  = '/ranking';
  static const activity = '/activity';
  static const profile  = '/profile';

  // Rutes amb paràmetres
  static const taskDetail = '/tasks/:taskId';
  static const cardDetail = '/cards/:cardId';
}