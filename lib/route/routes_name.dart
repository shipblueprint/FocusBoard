/// Centralized route name registry for FocusBoard.
///
/// Every navigable destination in the app has its name declared here so that
/// references throughout the codebase are compile-time safe and refactor-friendly.
class RoutesName {
  /// Main bottom-nav shell (Kanban / Eisenhower / Analytics).
  final appLayout = '/app';

  /// Kanban board.
  final kanban = '/app/kanban';

  /// Eisenhower matrix.
  final eisenhower = '/app/eisenhower';

  /// Analytics dashboard.
  final analytics = '/app/analytics';
}
