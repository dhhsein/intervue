# Riverpod vs Vanilla Provider — A Detailed Comparison

Both packages are authored by **Remi Rousselet**. Provider is the original, built on top of Flutter's `InheritedWidget`. Riverpod is its successor, designed from scratch to fix the limitations Remi encountered while maintaining Provider.

This guide walks through the top features of Riverpod, each with a simple use case and side-by-side implementations.

---

## Table of Contents

1. [Async Data Fetching (AsyncNotifier)](#1-async-data-fetching)
2. [Parameterized Providers (.family)](#2-parameterized-providers)
3. [No BuildContext Dependency](#3-no-buildcontext-dependency)
4. [Auto-Dispose](#4-auto-dispose)
5. [Compile-Time Safety](#5-compile-time-safety)
6. [Provider Overrides (Testing)](#6-provider-overrides-for-testing)
7. [Combining Providers](#7-combining-providers)
8. [Selective Rebuilds (select)](#8-selective-rebuilds)
9. [Pros and Cons Summary](#pros-and-cons-summary)

---

## 1. Async Data Fetching

**Use case:** Fetch a list of candidates from an API and show loading/error/data states.

### Vanilla Provider

```dart
// --- Model ---
class CandidatesModel extends ChangeNotifier {
  List<Candidate> candidates = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchCandidates() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      candidates = await api.getCandidates();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

// --- Widget ---
class CandidatesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<CandidatesModel>();

    if (model.isLoading) return CircularProgressIndicator();
    if (model.error != null) return Text('Error: ${model.error}');
    return ListView(
      children: model.candidates.map((c) => Text(c.name)).toList(),
    );
  }
}
```

You manually track `isLoading`, `error`, and `data` as three separate fields and call `notifyListeners()` at every state transition.

### Riverpod

```dart
// --- Provider ---
class CandidatesNotifier extends AsyncNotifier<List<Candidate>> {
  @override
  Future<List<Candidate>> build() async {
    return await api.getCandidates();
  }
}

final candidatesProvider =
    AsyncNotifierProvider<CandidatesNotifier, List<Candidate>>(
        CandidatesNotifier.new);

// --- Widget ---
class CandidatesPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCandidates = ref.watch(candidatesProvider);

    return asyncCandidates.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (candidates) => ListView(
        children: candidates.map((c) => Text(c.name)).toList(),
      ),
    );
  }
}
```

`AsyncValue` gives you `.when(loading, error, data)` for free. No manual boolean flags.

---

## 2. Parameterized Providers

**Use case:** Fetch screening data for a specific candidate by ID.

### Vanilla Provider

```dart
// There is no built-in way to parameterize a provider.
// Common workarounds:

// Option A: Pass the ID into a method after construction
class ScreeningModel extends ChangeNotifier {
  ScreeningData? data;
  bool isLoading = false;

  Future<void> load(String candidateId) async {
    isLoading = true;
    notifyListeners();
    data = await api.getScreening(candidateId);
    isLoading = false;
    notifyListeners();
  }
}

// Widget must call load() manually, usually in initState or didChangeDependencies.
// If multiple widgets need different candidate IDs, you need multiple provider instances
// or a Map<String, ScreeningData> inside one provider.

// Option B: Nest a new Provider for each ID in the widget tree
// This gets messy fast.
```

### Riverpod

```dart
// --- Provider ---
class ScreeningNotifier extends FamilyAsyncNotifier<ScreeningData, String> {
  @override
  Future<ScreeningData> build(String candidateId) async {
    return await api.getScreening(candidateId);
  }
}

final screeningProvider =
    AsyncNotifierProvider.family<ScreeningNotifier, ScreeningData, String>(
        ScreeningNotifier.new);

// --- Widget ---
// Just pass the ID. Done.
final asyncScreening = ref.watch(screeningProvider('candidate_123'));
```

`.family` creates a unique provider instance per parameter value. Each instance has its own lifecycle, loading state, and cache.

---

## 3. No BuildContext Dependency

**Use case:** One provider needs to read another provider's value (e.g., data service needs auth token).

### Vanilla Provider

```dart
// You MUST have a BuildContext to read a provider.
// This means service-layer code can't easily access other providers.

class CandidatesModel extends ChangeNotifier {
  // Can't access AuthModel here without passing context or injecting manually.
  // Typical workaround: pass dependencies through the constructor.

  final AuthModel auth;
  CandidatesModel(this.auth);

  Future<void> fetch() async {
    final token = auth.token; // manually injected
    candidates = await api.getCandidates(token);
    notifyListeners();
  }
}

// In the widget tree, you have to wire this up carefully:
ChangeNotifierProxyProvider<AuthModel, CandidatesModel>(
  create: (ctx) => CandidatesModel(ctx.read<AuthModel>()),
  update: (ctx, auth, prev) => prev!..auth = auth,
);
// ProxyProvider is verbose and error-prone.
```

### Riverpod

```dart
// --- Auth provider ---
final authProvider = StateProvider<String?>((ref) => null);

// --- Candidates provider reads auth directly via ref ---
class CandidatesNotifier extends AsyncNotifier<List<Candidate>> {
  @override
  Future<List<Candidate>> build() async {
    final token = ref.watch(authProvider);  // no BuildContext needed
    return await api.getCandidates(token);
  }
}
```

`ref` is available everywhere — in providers, notifiers, and widgets. No `ProxyProvider` gymnastics.

---

## 4. Auto-Dispose

**Use case:** When the user navigates away from a candidate's detail page, clean up that candidate's data from memory.

### Vanilla Provider

```dart
// Provider does not auto-dispose. You have two options:
//
// 1. Keep everything in memory forever (simple but wasteful).
//
// 2. Manually dispose by scoping providers in the widget tree:
//    Wrap a sub-tree with a new Provider that gets disposed when
//    the widget is removed. This requires careful widget tree design.

class CandidateDetailPage extends StatefulWidget {
  @override
  State createState() => _CandidateDetailPageState();
}

class _CandidateDetailPageState extends State<CandidateDetailPage> {
  late CandidateDetailModel _model;

  @override
  void initState() {
    super.initState();
    _model = CandidateDetailModel();
    _model.load(widget.candidateId);
  }

  @override
  void dispose() {
    _model.dispose(); // manual cleanup
    super.dispose();
  }
}
```

### Riverpod

```dart
// autoDispose: when no widget is watching this provider, it disposes automatically.
final candidateDetailProvider = AsyncNotifierProvider.autoDispose
    .family<CandidateDetailNotifier, Candidate, String>(
        CandidateDetailNotifier.new);

// That's it. Navigate away → provider is disposed → memory freed.
// Navigate back → provider rebuilds fresh.
```

One modifier (`.autoDispose`) handles the entire lifecycle. No `StatefulWidget` boilerplate for cleanup.

---

## 5. Compile-Time Safety

**Use case:** Read a provider that exists somewhere in the app.

### Vanilla Provider

```dart
// This compiles fine but CRASHES at runtime if AuthModel
// is not in the widget tree above this widget:
final auth = context.read<AuthModel>();

// Common runtime error:
// "Could not find the correct Provider<AuthModel> above this Widget"
//
// This happens when:
// - You forgot to add the provider in main.dart
// - The widget is in a different Navigator branch
// - The provider is below this widget in the tree, not above it
```

### Riverpod

```dart
// Providers are global declarations. They always exist.
final authProvider = StateProvider<String?>((ref) => null);

// This can NEVER throw a "provider not found" error:
final auth = ref.read(authProvider);

// If you misspell or reference a non-existent provider, the Dart
// compiler catches it immediately — it's just a variable reference.
```

Riverpod eliminates the entire category of "provider not found" runtime crashes.

---

## 6. Provider Overrides for Testing

**Use case:** Test a widget that depends on a data service, using a mock instead of the real one.

### Vanilla Provider

```dart
// You have to manually wrap your widget in a Provider that supplies the mock:
testWidgets('shows candidates', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CandidatesModel>(
          create: (_) => MockCandidatesModel(),
        ),
        // Must also provide every other provider the widget tree needs,
        // even if this test doesn't care about them.
        ChangeNotifierProvider<AuthModel>(
          create: (_) => MockAuthModel(),
        ),
      ],
      child: MaterialApp(home: CandidatesPage()),
    ),
  );
});
```

### Riverpod

```dart
testWidgets('shows candidates', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Override ONLY what you need. Everything else uses real defaults.
        candidatesProvider.overrideWith(() => MockCandidatesNotifier()),
      ],
      child: MaterialApp(home: CandidatesPage()),
    ),
  );
});
```

`ProviderScope.overrides` lets you surgically replace individual providers. No need to re-provide the entire dependency tree.

---

## 7. Combining Providers

**Use case:** Show a filtered list of candidates based on a search query and a status filter.

### Vanilla Provider

```dart
// Option A: One big model that holds everything
class DashboardModel extends ChangeNotifier {
  String query = '';
  String statusFilter = 'all';
  List<Candidate> _allCandidates = [];

  List<Candidate> get filtered => _allCandidates.where((c) {
    final matchesQuery = c.name.toLowerCase().contains(query.toLowerCase());
    final matchesStatus = statusFilter == 'all' || c.status == statusFilter;
    return matchesQuery && matchesStatus;
  }).toList();

  void setQuery(String q) { query = q; notifyListeners(); }
  void setStatus(String s) { statusFilter = s; notifyListeners(); }
  Future<void> load() async {
    _allCandidates = await api.getCandidates();
    notifyListeners();
  }
}

// Option B: ProxyProvider combining multiple models
// Gets complex and hard to follow quickly.
```

### Riverpod

```dart
// Each concern is its own provider:
final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<String>((ref) => 'all');

// Derived provider automatically recomputes when any dependency changes:
final filteredCandidatesProvider = Provider<AsyncValue<List<Candidate>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final status = ref.watch(statusFilterProvider);
  final asyncCandidates = ref.watch(candidatesProvider);

  return asyncCandidates.whenData((candidates) {
    return candidates.where((c) {
      final matchesQuery = c.name.toLowerCase().contains(query.toLowerCase());
      final matchesStatus = status == 'all' || c.status == status;
      return matchesQuery && matchesStatus;
    }).toList();
  });
});
```

Providers can `ref.watch` other providers to create reactive dependency chains. Each piece is small, testable, and recomposable.

---

## 8. Selective Rebuilds

**Use case:** A widget only cares about the candidate count, not the full list. Don't rebuild when a candidate's name changes.

### Vanilla Provider

```dart
// context.watch<CandidatesModel>() rebuilds on ANY change to the model.
// To avoid unnecessary rebuilds, you need Selector:
class CandidateCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.select<CandidatesModel, int>(
      (model) => model.candidates.length,
    );
    return Text('$count candidates');
  }
}
// Selector works but is verbose and easy to forget.
// Most developers just use context.watch and accept over-rendering.
```

### Riverpod

```dart
// select() works the same way but is more natural in the ref.watch pattern:
class CandidateCount extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      candidatesProvider.select((async) => async.valueOrNull?.length ?? 0),
    );
    return Text('$count candidates');
  }
}
```

Both support selective rebuilds, but Riverpod's `select` integrates more naturally since `ref.watch` is already the standard pattern.

---

## Pros and Cons Summary

### Riverpod — Pros

| Advantage | Impact |
|---|---|
| **Built-in async states** | Eliminates manual `isLoading`/`error` boilerplate |
| **`.family` parameterization** | One-liner for per-ID providers |
| **No BuildContext required** | Providers can reference each other freely |
| **Auto-dispose** | Automatic memory cleanup when providers are no longer watched |
| **Compile-time safety** | No "provider not found" runtime crashes |
| **Clean test overrides** | Override individual providers without re-providing the entire tree |
| **Reactive composition** | Providers watch other providers to form dependency chains |
| **Immutable state encouraged** | `AsyncValue` and sealed state patterns reduce mutation bugs |

### Riverpod — Cons

| Disadvantage | Impact |
|---|---|
| **Steeper learning curve** | More concepts: `Provider`, `StateProvider`, `NotifierProvider`, `AsyncNotifierProvider`, `.family`, `.autoDispose`, `ref.watch` vs `ref.read` vs `ref.listen` |
| **More boilerplate** | Defining an `AsyncNotifierProvider` requires a class + a top-level variable. Code generation (`@riverpod`) exists to reduce this but adds build_runner dependency |
| **Global state by design** | Providers are top-level declarations rather than widget-tree-scoped. Dependency relationships are less visually obvious |
| **Community/ecosystem** | Some Flutter packages and tutorials assume vanilla Provider. FlutterFire UI widgets use Provider out of the box |
| **Not officially blessed** | Provider is recommended in Flutter's official docs. Riverpod is a third-party package (though by the same author and widely adopted) |
| **Overkill for simple apps** | If your app has 2-3 simple state objects with no async, Provider's `ChangeNotifier` + `Consumer` does the job with less abstraction |
| **Migration cost** | Moving from Provider to Riverpod requires touching every widget that reads state (replace `context.watch` → `ref.watch`, `StatelessWidget` → `ConsumerWidget`) |

### When to Use Which

| Scenario | Recommendation |
|---|---|
| Simple app, few state objects, no async | **Vanilla Provider** — less to learn, less boilerplate |
| Async data fetching from APIs/databases | **Riverpod** — `AsyncNotifier` and `AsyncValue` pay for themselves immediately |
| Parameterized data (e.g., detail pages by ID) | **Riverpod** — `.family` has no clean equivalent in Provider |
| Large app with many interdependent providers | **Riverpod** — reactive composition and `ref.watch` chains scale better |
| Need strong testability with minimal setup | **Riverpod** — `ProviderScope.overrides` is cleaner than manual `MultiProvider` in tests |
| Team new to Flutter | **Vanilla Provider** — simpler mental model to start with |
