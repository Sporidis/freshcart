# freshcart_domain

The pure Dart core of FreshCart: entities, value objects, the `Result` / `Failure`
union, repository ports and use cases. **Both the app and the server depend on it**, so
a rule such as "an item name is 1–80 characters" is written once and enforced on both
sides.

## The one rule

This package must never import Flutter, Serverpod, Firebase, `freshcart_client` or any
I/O package. CI greps for those imports on every push. If you need one of them, the code
belongs in a feature's `data/` layer instead, behind a port defined here.

## What lives here

| Kind | Examples |
| --- | --- |
| Entities | `ShoppingList`, `ShoppingItem`, `Shop` (freezed, no JSON) |
| Ids | extension types, so a `ListId` can't be passed where an `ItemId` is expected |
| Rules | statics on the entity, such as `ShoppingItem.validateName` |
| Ports | `ListRepository`, `ItemRepository`, `ShopRepository`, `AuthRepository`, `NotificationRepository` |
| Use cases | verbs such as `AddItem` and `JoinList`: apply the rules, then call ports |
| Errors | `Result<T>` = `Ok(value)` / `Err(Failure)`; no exceptions for expected failures |

## Commands

```bash
dart run build_runner build   # freezed output is not committed
dart test
```
