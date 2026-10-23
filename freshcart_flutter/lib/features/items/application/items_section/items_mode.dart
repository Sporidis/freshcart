/// What the items area is doing right now. Only one at a time.
///
/// One value instead of three booleans (rearranging, selecting, searching).
/// With booleans, every widget would need to decide which one wins.
/// `ItemsSectionController` decides that once.
enum ItemsMode { browse, search, select, rearrange }
