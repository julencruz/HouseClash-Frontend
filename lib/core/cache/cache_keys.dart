abstract class CacheKeys {
  static String taskList(String houseId)  => 'tasks:house:$houseId';
  static String myTasks(String userId)    => 'tasks:mine:$userId';
  static String taskDetail(String taskId) => 'tasks:detail:$taskId';

  static String houseDetails(String houseId) => 'house:details:$houseId';
  static String houseMembers(String houseId) => 'house:members:$houseId';
  static String ranking(String houseId)      => 'house:ranking:$houseId';

  static String cardInventory(String userId) => 'cards:inventory:$userId';
  static String cardPacks()                  => 'cards:packs';

  static String categories(String houseId) => 'categories:$houseId';

  static String activity(String houseId) => 'activity:$houseId';
}