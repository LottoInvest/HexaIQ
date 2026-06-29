enum ScreenClass { compact, medium, expanded }

class LayoutBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;

  static ScreenClass classify(double width) {
    if (width >= expanded) {
      return ScreenClass.expanded;
    }
    if (width >= medium) {
      return ScreenClass.medium;
    }
    return ScreenClass.compact;
  }
}
