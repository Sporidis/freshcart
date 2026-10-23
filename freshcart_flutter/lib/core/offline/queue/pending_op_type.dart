/// What kind of change a queued row is.
///
/// Together with [PendingEntityType] (item or list), this tells
/// [QueueDrainer] which repository method to call.
///
/// - `create` is used for both new items and new lists.
/// - `edit` covers every item change (check, rename, reorder...), because
///   they all go through the same `save()` method.
/// - Joining a list isn't here: it can't be done offline.
enum PendingOpType {
  create,
  edit,
  remove,
  clearChecked,
  removeMany,
  moveMany,
  rename,
  setClearCheckedAfterShopping,
  transferOwnership,
  leave,
  delete,
  removeMember,
}
