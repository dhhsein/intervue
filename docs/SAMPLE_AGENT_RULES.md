# AGENT GUIDANCE (Concise)

Guidelines for AI Agents working with this repository.

---

## Issue Tracking with Beads

This project uses **bd** (beads) for issue tracking. Beads tasks are managed purely through prompts - the user tells me when to create, update, or close tasks.

**Quick Reference:**
```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Mark task in progress
bd close <id>         # Complete work
bd sync               # Sync with git
```

**Workflow:**
- User tells me to create tasks → I run `bd create`
- User tells me to work on tasks → I run `bd update --status=in-progress`
- User tells me to close tasks → I run `bd close`
- Git hooks automatically save Beads state during user's manual commits

---

## Branch Naming Convention

Use the following prefixes for branch names:
- **UM-XX**: Mobile app changes (`mobile_app/`)
- **UW-XX**: Web app changes (`web_app/`)
- **UU-XX**: General changes (cloud functions, security rules, configs, setups, etc.)

---

## Monorepo Structure

This is a monorepo containing:
- **mobile_app/**: Flutter mobile app (iOS & Android) for athletes/users
- **web_app/**: Flutter web app for managers/admins
- **shared/**: Shared Flutter package (design system, models, utils)
- **functions/**: Firebase Cloud Functions

Most guidelines below apply primarily to the mobile app. Web and shared package conventions will be documented as they are established.

---

## Flutter / Dart Guidelines

### Widget State Management

**CRITICAL RULE - Avoid Stateful Parent Widgets**: Never make a parent widget stateful just because one of its child widgets needs state.

**Rationale**: Making a parent stateful pollutes the widget tree and creates unnecessary rebuilds. State should be localized to the smallest widget that needs it.

**Correct approach**: Create a separate stateful widget for the component that needs state, and use it as a child.

**Example**:

```dart
// ❌ BAD: Making parent stateful for one child's needs
class AppSidebar extends StatefulWidget {
  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = 'v${info.version}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Logo(),
        MenuItem1(),
        MenuItem2(),
        Text(_version), // Only this needs the state
      ],
    );
  }
}

// ✅ GOOD: Separate stateful widget for the component that needs state
class AppVersionDisplay extends StatefulWidget {
  const AppVersionDisplay({super.key});

  @override
  State<AppVersionDisplay> createState() => _AppVersionDisplayState();
}

class _AppVersionDisplayState extends State<AppVersionDisplay> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = 'v${info.version}');
  }

  @override
  Widget build(BuildContext context) {
    return Text(_version);
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Logo(),
        MenuItem1(),
        MenuItem2(),
        AppVersionDisplay(), // Self-contained stateful widget
      ],
    );
  }
}
```

**Benefits**:
- Better separation of concerns
- Parent widget remains stateless and simpler
- Only the necessary component rebuilds when state changes
- Easier to test and maintain
- Component becomes reusable

---

## Project Specs

- Flutter app targeted only for iOS and Android devices
- Uses Firebase for mobile backend
- Offline first support leveraged from Firebase

## Project Overview
A **Athlete Portfolio Management App** that:
- Allows athlete (users) to register and create their profile.
- Lets users add their achievements and records.
- Collects athlete information and shows to a dashboard app to rank and discover athletes.
- Shows programs created by managers to recruit athletes and sponsor them.
- Allows athletes to track their measurements and assessments.
- Enables athletes to raise request for sponsorships for various needs such as travel, training, etc.
- Provides a platform for athletes to update their current career status such as training, competing, injured, etc.
- Designed to be minimal, convenient, and one stop solution for an athlete career.

**Backend**: Firebase Cloud Firestore (data), Cloud Functions (server tasks), Firebase Auth (login).

---

## Web App Navigation Pattern

**CRITICAL RULE - Use context.go() for Navigation**: In the web app, always use `context.go()` for navigation (both forward and backward), never `context.push()` or `context.pop()`.

**Rationale:**
- `context.go()` updates the browser address bar to show route parameters (e.g., `/athletes/123`, `/achievements/userId/achievementId`)
- `context.push()` and `context.pop()` may not update the URL, resulting in IDs not showing in the address bar
- The app uses `StatefulShellRoute.indexedStack` which automatically preserves scroll position, filters, and state for each branch
- Therefore, using `context.go()` has no downside - it shows IDs in the URL while still preserving all page state

**Implementation Pattern:**

```dart
// ✅ CORRECT - Forward navigation
onTap: () => context.go('/athletes/$id'),

// ✅ CORRECT - Back navigation
onTap: () => context.go('/athletes'),

// ❌ WRONG - Does not show ID in URL
onTap: () => context.push('/athletes/$id'),
onTap: () => context.pop(),
```

**Key Benefits:**
- URLs are shareable and bookmarkable with IDs
- Browser back/forward buttons work correctly
- State (scroll position, filters) is preserved by StatefulShellRoute
- Consistent navigation pattern across the web app

---

## UI Pattern
- **Screens**: Each uses `Scaffold` (with optional `SafeArea`). Name ends with `Screen` (e.g., `PlanListScreen`).
- **Layouts**: Child of Scaffold, containing visual UI (e.g., `PlanListLayout`).
- **Views**: Dynamic sub-layouts within a Layout that are conditionally rendered based on state. Used for state-based UI switching within a single screen flow (e.g., `_buildLoginView()`, `_buildCreateAccountView()` within an auth layout). Not to be confused with Pages.
- **Pages**: Used only in `PageView` for swipeable multi-step flows (e.g., `UserProfilePage` in onboarding).
- **Components**: Reusable widgets with minimal required params.
- **Tokens**: Define colors, typography, spacing, border radius. No raw styles allowed.
- **Spacing**: CRITICAL RULE - Always use spacing tokens from `AppSpacing` class for all padding, margins, and SizedBox dimensions. Never use hardcoded numeric values. Spacing tokens are multiples of 4 and defined in `core/design/spacing_tokens.dart`
- **Large Spacing Pattern**: CRITICAL RULE - Never use spacing tokens larger than 48px (AppSpacing.p48). For layouts requiring large spaces between sections, use Column with `mainAxisAlignment: MainAxisAlignment.spaceBetween` and separate the UI into `_topSection()` and `_bottomSection()` widgets. This creates responsive layouts that adapt to different screen sizes instead of brittle fixed spacing.
- **Border Radius**: CRITICAL RULE - Always use border radius tokens from `AppBorderRadius` (for BorderRadius) and `AppRadius` (for individual Radius) classes. Never use hardcoded BorderRadius.circular() or Radius.circular() values. Tokens are multiples of 5 (r5, r10, r15, r20, r25) and defined in `core/design/border_radius_tokens.dart`

**Critical Rule**: In Screen widgets, the child of any `Consumer<Viewmodel>` must always be a Layout widget, never direct UI content. This enforces proper separation between routing/scaffold concerns (Screen) and UI logic (Layout). In cases where this rule needs to be violated, add an explicit note with a tag `AGENT RULE VIOLATION: <reason for violation>`.

---

## Architecture Pattern
Strict **MVVM**: Models, Repository, Viewmodels, Views.

- **Models**: Mirror Firestore structure for easier parsing.
- **Views (Layouts)**: UI components that consume Viewmodels. Should be StatelessWidget when possible. Handle error/loading via Viewmodels.
- **Viewmodels**: Business logic, form state management, and connect Views ↔ Repository. Manage TextEditingControllers for forms.
- **Repository**: Fetches from Firebase, parses into Models.

**CRITICAL RULE - Viewmodel Naming Convention**: Always use "Viewmodel" (not "ViewModel" or "ViewModel") in all file names, class names, variable names, and method names. This prevents confusion between `_model.dart` files (data models) and `_viewmodel.dart` files (view models). Examples:
- File: `auth_viewmodel.dart` (not `auth_view_model.dart`)
- Class: `AuthViewmodel` (not `AuthViewModel`)
- Variable: `authViewmodel` (not `authViewModel`)
- Method parameter: `(AuthViewmodel viewmodel)` (not `(AuthViewmodel viewModel)`)  


## Folder Structure

Refer FOLDER_STRUCTURE.md

---

## Adding Dependencies
- Use `flutter pub add`, never edit `pubspec.yaml` manually.  
- For dev dependencies: `flutter pub add --dev package_name`.

---

## Flutter Architecture Guidelines
Following [Flutter’s official guide](https://docs.flutter.dev/app-architecture/guide):

- **Service**: Wrap APIs (stateless).  
- **Repository**: Data source of truth (transform, cache, error handling).  
- **Viewmodel**: Manage UI state & business logic.  
- **View**: Compose UI, no business logic.  
- **Cross-Cutting**: Managers (coordination), Utilities (shared logic).  

**UI Hierarchy**:
- **Screen** → Scaffold, routes, transitions, ChangeNotifierProvider setup
- **Layout** → UI + Viewmodel consumption. Can be stateful for forms/local state
- **Views** → Dynamic sub-layouts within a Layout for state-based conditional rendering
- **Pages** → Multi-step states in PageView for swipeable flows (e.g., Onboarding)
- **Components** → Reusable atomic widgets

**CRITICAL RULE - HybridMVVM Pattern**: All screens must follow the **HybridMVVM** architecture pattern for optimal performance and maintainability:

### HybridMVVM Pattern Requirements:
1. **Screen** (StatelessWidget): Ultra-thin routing shell that only contains Scaffold. May provide viewmodel via ChangeNotifierProvider for complex forms, otherwise just navigates to Layout.
2. **Layout** (StatefulWidget or StatelessWidget): For simple forms with local viewmodel, StatefulWidget owns controllers and local viewmodel. For complex forms, StatelessWidget consumes global viewmodel via Consumer.
3. **Viewmodel** (ChangeNotifier): Two types:
   - **Local**: Simple UI state (isLoading). Created in Layout state, disposed in Layout.
   - **Global**: Complex form state with controllers. Provided in Screen, consumed in Layout.
4. **Domain** (ChangeNotifier): Global application-level state and business logic (e.g., AuthDomain for auth state). Provided globally via GlobalProvider. Returns Result for error handling.

### Domain vs Viewmodel Pattern:
The app uses a two-tier state management approach:
- **Domain (Global)**: E.g., `AuthDomain` - manages global authentication state (user session, auth status). Provided globally via `GlobalProvider` at app root. Used for routing decisions (GoRouter's `refreshListenable`). Accessed via `context.read<AuthDomain>()` in screens/layouts.
- **Viewmodel (Local/Global Hybrid)**: E.g., `AuthViewmodel` (local), `CreateProfileViewmodel` (global).
  - **Local Viewmodels**: Manage local UI state (isLoading). Created locally within Layout's State class. NOT provided globally. Used for simple loading states within a single screen flow.
  - **Global Viewmodels**: Manage complex form state with controllers (TextEditingController, FocusNode). Provided via ChangeNotifierProvider in Screen. Used when controllers need to be managed by viewmodel.

Domain methods return Result<void, String> for success/error handling in layouts:
```dart
// AuthDomain (global)
class AuthDomain extends ChangeNotifier {
  Future<Result<void, String>> signIn(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      return Result.failure('Please fill in all fields');
    }

    final result = await _authService.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (result.isFailure) {
      return Result.failure(result.errorMessage ?? 'Sign in failed');
    }

    return Result.success(null);
  }
}

// AuthViewmodel (local, simple UI state)
class AuthViewmodel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

// Layout usage (local viewmodel instance)
class _GetStartedLayoutState extends State<GetStartedLayout> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthViewmodel _authViewmodel = AuthViewmodel(); // Local instance

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _authViewmodel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authViewmodel,
      builder: (context, child) {
        return AppButton(
          onTap: _handleSignIn,
          isLoading: _authViewmodel.isLoading,
        );
      },
    );
  }

  Future<void> _handleSignIn() async {
    _authViewmodel.setLoading(true);
    final authDomain = context.read<AuthDomain>();
    final result = await authDomain.signIn(
      emailController.text,
      passwordController.text,
    );
    _authViewmodel.setLoading(false);

    if (result.isFailure) {
      if (mounted) {
        AppSnackbar.show(
          context,
          result.errorMessage ?? 'Sign in failed',
          variant: AppSnackbarVariant.error,
        );
      }
    }
  }
}
```

This pattern ensures:
- Router only rebuilds on auth state changes (AuthDomain), not on loading states (AuthViewmodel)
- UI state is scoped to specific screens, preventing unnecessary global rebuilds
- Clear separation: Domain = business logic + global state, Viewmodel = UI state only
- Domain methods return Result for layout to handle errors via snackbars
- Each layout creates and disposes its own local AuthViewmodel instance
- Controllers owned by layout (not viewmodel) for simple forms
- For complex forms, use global viewmodels that own controllers (see CreateProfileViewmodel pattern)

### Pattern Structure (Local Viewmodel):
```dart
// Screen - StatelessWidget, only routing/scaffold
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GetStartedLayout(),
    );
  }
}

// Layout - StatefulWidget, owns controllers AND local viewmodel
class GetStartedLayout extends StatefulWidget {
  const GetStartedLayout({super.key});

  @override
  State<GetStartedLayout> createState() => _GetStartedLayoutState();
}

class _GetStartedLayoutState extends State<GetStartedLayout> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthViewmodel _authViewmodel = AuthViewmodel(); // Local instance

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _authViewmodel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authViewmodel,
      builder: (context, child) {
        return AppButton(
          label: 'Sign In',
          onTap: _handleSignIn,
          isLoading: _authViewmodel.isLoading,
        );
      },
    );
  }

  Future<void> _handleSignIn() async {
    _authViewmodel.setLoading(true);
    final authDomain = context.read<AuthDomain>();
    final result = await authDomain.signIn(
      emailController.text,
      passwordController.text,
    );
    _authViewmodel.setLoading(false);

    if (result.isFailure) {
      if (mounted) {
        AppSnackbar.show(
          context,
          result.errorMessage ?? 'Sign in failed',
          variant: AppSnackbarVariant.error,
        );
      }
    }
  }
}
```

### Pattern Structure (Global Viewmodel):
```dart
// Screen - Provides global viewmodel
class CreateProfileScreen extends StatelessWidget {
  const CreateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateProfileViewmodel(),
      child: const Scaffold(body: CreateProfileLayout()),
    );
  }
}

// Viewmodel - Owns controllers for complex forms
class CreateProfileViewmodel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<Result<void, String>> submitProfile() async {
    // Business logic and validation
    _setLoading(true);
    // ... save logic ...
    _setLoading(false);
    return Result.success(null);
  }

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    super.dispose();
  }
}

// Layout - Consumes global viewmodel
class CreateProfileLayout extends StatelessWidget {
  const CreateProfileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateProfileViewmodel>(
      builder: (context, viewmodel, _) {
        return AppButton(
          onTap: () => _handleSubmit(context, viewmodel),
          isLoading: viewmodel.isLoading,
        );
      },
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    CreateProfileViewmodel viewmodel,
  ) async {
    final result = await viewmodel.submitProfile();
    if (result.isFailure && context.mounted) {
      AppSnackbar.show(context, result.errorMessage!);
    }
  }
}
```

### Benefits:
- **Router Optimization**: Router only rebuilds on Domain changes (auth state), not UI state (loading)
- **Flexibility**: Choose local viewmodels for simple forms, global viewmodels for complex forms
- **Clear error handling**: Domain returns Result, layout shows errors via snackbars
- **Scoped State**: Local viewmodels prevent global state pollution
- **Clean separation**: Screen = routing, Layout = UI + controllers (simple) or consumes viewmodel (complex), Domain = global state + business logic, Viewmodel = UI state + form logic (when needed)

### Key Differences from Traditional MVVM:
- **Two patterns**: Local viewmodel (simple forms with layout-owned controllers) vs Global viewmodel (complex forms with viewmodel-owned controllers)
- **Result-based error handling**: Domain returns Result<T, String>, not throwing exceptions or passing viewmodel
- Screens are **stateless** routing shells (except when providing viewmodel)
- **Domain** handles business logic and returns success/failure status
- Only ListenableBuilder/Consumer children rebuild when viewmodel changes

### RULE VIOLATION Tag:
Any screen that does NOT follow the HybridMVVM pattern must be marked with:
```dart
// HYBRIDMVVM RULE VIOLATION: <reason for violation>
```
This tag should be placed at the class definition level to indicate non-compliance.

---

## Service Call Wrapping Rule

**CRITICAL RULE - Viewmodels Must Wrap Service Calls**: Viewmodels must wrap all service calls. Screens/layouts cannot call services directly.

**Rationale:**
- Maintains separation of concerns
- Centralizes business logic and state management in viewmodels
- Makes testing easier (mock viewmodel instead of service)
- Provides consistent data access patterns across the app

**Implementation:**

```dart
// ✅ CORRECT: Viewmodel wraps service
class AthleteDetailViewmodel extends ChangeNotifier {
  final AthleteService _service = AthleteService();

  bool _isLoading = false;
  AthleteData? _athlete;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  AthleteData? get athlete => _athlete;
  String? get errorMessage => _errorMessage;

  Future<void> loadAthleteById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _athlete = await _service.getAthleteById(id);
      if (_athlete == null) {
        _errorMessage = 'Athlete not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load athlete details. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Layout uses viewmodel
class _AthleteDetailLayoutState extends State<AthleteDetailLayout> {
  final AthleteDetailViewmodel _viewmodel = AthleteDetailViewmodel();

  @override
  void initState() {
    super.initState();
    _loadAthlete();
  }

  Future<void> _loadAthlete() async {
    await _viewmodel.loadAthleteById(widget.athleteId);

    if (_viewmodel.errorMessage != null && mounted) {
      AppSnackbar.showError(context, _viewmodel.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewmodel,
      builder: (context, child) {
        if (_viewmodel.isLoading) return LoadingIndicator();
        if (_viewmodel.athlete == null) return NotFoundView();
        return AthleteView(athlete: _viewmodel.athlete!);
      },
    );
  }
}
```

```dart
// ❌ INCORRECT: Layout calling service directly
class _AthleteDetailLayoutState extends State<AthleteDetailLayout> {
  final AthleteService _service = AthleteService();  // ❌ Should not be here
  final AthleteDetailViewmodel _viewmodel = AthleteDetailViewmodel();

  AthleteData? _athlete;  // ❌ State should be in viewmodel

  Future<void> _loadAthlete() async {
    final athlete = await _service.getAthleteById(widget.athleteId);  // ❌
    setState(() {
      _athlete = athlete;  // ❌
    });
  }
}
```

**Exceptions:**

Service calls can be made directly from screens/layouts only when:
1. No viewmodel exists for the feature (e.g., logout function using AuthService directly)
2. The operation is a one-time utility action that doesn't affect screen state

**Examples of Exceptions:**
- Logout button calling `AuthService.signOut()` directly
- Copy-to-clipboard utility that doesn't affect UI state
- One-time configuration actions on app startup

For all data loading and state management, always use viewmodels.

---

## Data Flow & State Management
1. Auth: Firebase Auth → `AuthDomain`
2. Data: Services → Firestore
3. State: Provider (Domains globally, some Viewmodels locally/globally)
4. Context: Scoped to authenticated user
5. Offline: Firebase built-in

**State tree**:
```
GlobalProvider
├── AuthDomain (global auth state)
└── OnboardingDomain (global onboarding state)

Per-Screen Providers (when needed):
└── CreateProfileViewmodel (complex form state)
```

---

## Testing Standards
- Test **user flows**, not implementation details.  
- Minimal tests (1–3 per feature).  
- Organize by **scenarios** (sunny day, edge, error).  
- Prefer scenario-based over small fragmented tests.  
- Use **override-based call tracking** for mocks instead of `mocktail`, except in complex cases. 
- Never adjust screen size in tests.  

**File structure**:
```
test/features/[feature]/api_request_helpers/
├── api_request_helpers.dart
└── request_handlers.dart
```

---

## Development Setup
- **Flutter**: FVM-managed (v3.29.2)  
- **iOS**: ≥ 14.0  
- **Android**: min SDK 21, target latest  
- **Env vars**: API keys required  
- **Line length**: 120 chars  

---

## Key Dependencies
- State: Provider  
- Routing: GoRouter  
- Auth: FirebaseAuth  
- Analytics: Firebase Analytics  
- Codegen: `dart_json_mapper` + build_runner  
- Testing: Mocktail  

---

## Firebase Configuration

### Firestore Security Rules

**CRITICAL RULE - Multi-App Security Considerations**: When modifying `firestore.rules`, always consider both mobile and web app access patterns and use cases:

- **Mobile App**: Queries single-user subcollections (`users/{userId}/achievements`)
  - Users read/write their own data: `allow read, write: if isOwner(userId)`
  - Requires COLLECTION scope rules

- **Web App**: Queries across all users via collection group queries (`collectionGroup('achievements')`)
  - Managers/admins read all users' data: `allow read: if isManager()`
  - Requires COLLECTION_GROUP scope rules

**Pattern**: Use both collection-specific rules AND collection group rules:

```javascript
// Collection group queries (web app - managers/admins)
match /{path=**}/achievements/{achievementId} {
  allow read: if isManager();
  allow update: if isManager();
}

// Single user subcollection (mobile app - users)
match /users/{userId} {
  match /achievements/{achievementId} {
    allow read: if isOwner(userId) || isManager();
    allow create: if isOwner(userId) && request.resource.data.status == 'pending';
    allow update: if isOwner(userId) && request.resource.data.status == resource.data.status;
    allow delete: if isOwner(userId);
  }
}
```

### Firestore Indexes

**CRITICAL RULE - Index Scope Management**: When modifying `firestore.indexes.json`, you MUST define indexes for BOTH query scopes based on app usage:

**Understanding Index Scopes:**

1. **COLLECTION scope**: For queries on single subcollection paths
   - Example: Mobile app queries ONE user's achievements
   - Query: `users/{userId}/achievements` ordered by `createdAt`
   - Fast, efficient for single-user data

2. **COLLECTION_GROUP scope**: For queries across ALL subcollections with same name
   - Example: Web app queries ALL users' achievements
   - Query: `collectionGroup('achievements')` ordered by `createdAt`
   - Enables cross-user queries for admin dashboards

**CRITICAL BEHAVIOR - Auto-Index Deletion**: When you create/deploy `firestore.indexes.json`:
- Firestore **deletes ALL auto-created indexes** for fields defined in the file
- Firestore **only maintains the indexes you explicitly define**
- If you only define COLLECTION_GROUP indexes, COLLECTION queries will fail
- If you only define COLLECTION indexes, COLLECTION_GROUP queries will fail

**Required Pattern**: Always define BOTH scopes when needed:

```json
{
  "indexes": [
    {
      "collectionGroup": "achievements",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "achievements",
      "fieldPath": "createdAt",
      "indexes": [
        {
          "queryScope": "COLLECTION_GROUP",
          "order": "DESCENDING"
        },
        {
          "queryScope": "COLLECTION",
          "order": "DESCENDING"
        }
      ]
    }
  ]
}
```

**Verification Checklist** when modifying indexes:
- [ ] Mobile app subcollection queries have COLLECTION scope indexes
- [ ] Web app collection group queries have COLLECTION_GROUP scope indexes
- [ ] Both ascending/descending orders defined if queries use both
- [ ] Composite indexes include all fields used in `where()` + `orderBy()` clauses
- [ ] Deploy with `firebase deploy --only firestore:indexes`
- [ ] Test both mobile and web apps after deployment

**Common Pitfall**: Adding indexes for web app (COLLECTION_GROUP) breaks mobile app (COLLECTION) because auto-created COLLECTION indexes are deleted. Always explicitly define both scopes.

---

## Code Standards
- **Imports**: Always use relative imports (`../`) for files within `lib/` directory, following official Dart guidelines. This is enforced by the `prefer_relative_imports` linter rule. Relative imports are shorter, cleaner, and recommended by the Dart team for better maintainability.
- **Line Length**: All code must adhere to 80 character line limit (Dart default). This is enforced by:
  - VS Code settings (`.vscode/settings.json`)
  - Dart formatter configuration (`page_width: 80` in `analysis_options.yaml`)
  - Analysis options (default 80-character linting)
  - All analysis tools and formatters are configured for 80 char limit
- **Codegen**: Run `just build-runner` after JSON changes  
- **Functions**: Follow SRP, no redundant 1-line wrappers
- **Comments**:
  - **CRITICAL RULE - No Comments**: Never add comments in code. If clarity is needed, make the code more readable by using descriptive variable names, method names, and extracting complex logic into private methods with clear names. Comments indicate unclear code that should be refactored.
  - **Exception**: TODO comments are allowed and should be kept to track pending work.
- **UI Standards**:
  - Always use `AppButton` (no native buttons).
  - **CRITICAL RULE - Use AppText Only**: Never use the native `Text()` widget directly. Always use `AppText` component for all text display. This ensures consistent typography, theming, and design system compliance across the app.
  - **CRITICAL RULE - Default Text Color**: Never explicitly set `color: AppColors.grey0` on any text styling (Text, AppText, TextStyle.copyWith, etc.), as grey0 is the default text color in the theme. Only specify color when using a non-default color. This keeps code clean and ensures proper theme consistency.
  - **CRITICAL RULE - Use AppLoader for Loading States**: Never use `CircularProgressIndicator()` directly. Always use `AppLoader` component for loading screens. This ensures consistent loading UI across the app.
  - Use `AppColorScheme` (no direct `Theme.of`).
  - **CRITICAL RULE - UI Extraction**: Break complex UI into private builder methods (`_buildXYZ()`). Extract any widget that spans more than 5-7 lines or represents a logical UI section. Method names must be descriptive (e.g., `_buildHeroImage()`, `_buildWelcomeText()`, `_buildBottomSection()`). This improves readability, maintainability, and follows single responsibility principle.
  - **CRITICAL RULE - Builder Method Naming Convention**: Follow consistent naming for builder methods:
    - **State methods** use "State" suffix: `_buildLoadingState()`, `_buildErrorState()`, `_buildEmptyState()`, `_buildNotFound()` (or `_buildNotFoundState()`)
    - **Content methods** use descriptive names with "Content" suffix or specific descriptive names: `_buildAthleteContent()`, `_buildDetailsContent()`, `_buildAchievementsList()`, `_buildFormContent()`
    - **NEVER use generic names** like `_buildLoadedState()` for main content - this is too generic and non-descriptive
    - Examples:
      ```dart
      // ❌ WRONG - Too generic
      Widget _buildLoadedState() { ... }

      // ✅ CORRECT - Descriptive state method
      Widget _buildLoadingState() { ... }
      Widget _buildErrorState() { ... }

      // ✅ CORRECT - Descriptive content method
      Widget _buildAthleteContent() { ... }
      Widget _buildAchievementsList() { ... }
      Widget _buildDetailsContent() { ... }
      ```
  - **CRITICAL RULE - Ternary Operator Readability**: For ternary operators where either branch contains multi-line statements, always extract the logic into private methods. Use `condition ? _buildMethod1() : _buildMethod2()` instead of inline multi-line expressions. This significantly improves code readability and maintainability.
  - **CRITICAL RULE - Early Return Pattern**: Always prefer early return statements over nested if-else chains when possible. Use `if (condition) return value;` followed by the default case. This reduces nesting, improves readability, and makes the code flow more linear and easier to follow. Apply this pattern systematically across all methods to eliminate unnecessary else branches and reduce cyclomatic complexity.
  - **CRITICAL RULE - Default Background Color**: Never set `backgroundColor: Colors.white` or `backgroundColor: AppColors.grey100` on Scaffold widgets, as white/grey100 is the default surface color in the theme. Let the theme's surface color be used by default. Only set explicit backgroundColor when a different color is actually needed (e.g., `backgroundColor: AppColors.grey25` for dark screens). This ensures proper theme consistency and automatic light/dark mode support.
  - **CRITICAL RULE - Layout State Management**: Layouts are typically StatefulWidget when they need form controllers, focus management, or local viewmodel instances. Use StatelessWidget only for simple presentational layouts with no local state.
  - **CRITICAL RULE - ListenableBuilder Pattern**: When using local viewmodels, always use `ListenableBuilder` to listen to viewmodel changes. Handle errors inline in action methods by checking Result.isFailure and showing snackbars. This keeps error handling close to the action that triggers it.
  - **CRITICAL RULE - Consumer Usage**: Only use `Consumer` for global state from providers (e.g., `Consumer<CreateProfileViewmodel>` when viewmodel is provided via ChangeNotifierProvider in Screen, `Consumer<AuthDomain>` for global domains). For local viewmodels created in Layout state, use `ListenableBuilder` instead.
  - No colons in titles, no primary-colored icons, consistent button placement rules.
- **Color System**: 
  - **CRITICAL RULE**: All colors must be used via ColorScheme extensions, never hardcoded in widgets.
  - Use `context.colorScheme.primary` instead of `AppColors.brand50` or `Colors.blue`.
  - Use `context.colorScheme.surface` for backgrounds, `context.colorScheme.onSurface` for text, etc.
  - Use `context.textTheme.headlineMedium` instead of `Theme.of(context).textTheme.headlineMedium`.
  - Manual color usage must include `// NOTE: AGENT RULE VIOLATION: <proposed ColorScheme alternative>`.
  - Examples of violations and fixes:
    - `color: Colors.blue` → `// NOTE: AGENT RULE VIOLATION: Use context.colorScheme.primary`
    - `fillColor: AppColors.grey95` → `// NOTE: AGENT RULE VIOLATION: Use context.colorScheme.surfaceVariant`
    - `backgroundColor: Colors.green` → `// NOTE: AGENT RULE VIOLATION: Use context.colorScheme.primaryContainer`
    - `Theme.of(context).textTheme.bodyLarge` → `// NOTE: Use context.textTheme.bodyLarge (cleaner syntax)`
  - Only define colors in `core/colors.dart` and use them in ColorScheme definitions in `theme.dart`.
- **Boolean Variable Standards**:
  - All boolean properties/variables must start with "is" prefix for easier identification (e.g., `isLoading`, `isEmailVerified`).
  - Never invert boolean variables directly in code using `!` operator.
  - Instead, define negation getters in the containing class/Viewmodel (e.g., `bool get isNotEmailVerified => !isEmailVerified`).
  - Use descriptive getter names for better readability in consuming code.
- **Model Field Value Standards**:
  - **CRITICAL RULE - No Hardcoded String Comparisons**: Never use hardcoded string literals when comparing model field values outside the model class itself. String literals for field values (e.g., `'Para-Athlete'`, `'Regular'`, `'Active'`, `'Pending'`) should only appear in:
    1. The model class getters/methods
    2. Firestore serialization/deserialization (fromJson/toJson)
  - Always expose field values through type-safe getters in the model class:
    ```dart
    // ❌ WRONG - Hardcoded string in UI/business logic
    if (profile.athleteType == 'Para-Athlete') { ... }

    // ✅ CORRECT - Use getter in model
    class PersonalProfileData {
      final String? athleteType;

      bool get isParaAthlete => athleteType == 'Para-Athlete';
      bool get isRegularAthlete => athleteType == 'Regular';
    }

    // Usage in UI/business logic
    if (profile.isParaAthlete) { ... }
    ```
  - **Benefits**: Type safety, refactoring safety, single source of truth, prevents typos
  - **Exception**: Constants classes can be used as an intermediate step: `if (profile.athleteType == AthleteConstants.typePara)`, but getters are preferred for cleaner API
- **Form Validation**:
  - **CRITICAL RULE - Validation in ViewModels Only**: All form validation logic must be implemented in ViewModels, never in UI components (Layouts/Screens). This enforces proper separation of concerns and keeps business logic out of the UI layer. UI components should only display validation state and error messages provided by ViewModels.
  - **CRITICAL RULE - Clear Errors on User Action**: When validation error messages are displayed, they should be cleared as soon as the user starts taking corrective action. Typically, this means clearing error messages when a text field gains focus (onFocusChange). This provides immediate feedback that the user is addressing the issue and prevents confusion about whether their input will be validated.
- **Authentication-Based Routing**:
  - **CRITICAL RULE - Domain-Driven Navigation**: Authentication routing is handled automatically via `GoRouter.refreshListenable` listening to `AuthDomain`. When `AuthDomain` notifies listeners (on Firebase auth state changes), the router's redirect function evaluates and navigates accordingly. The router redirects unauthenticated users to `/auth` and authenticated users away from `/auth` to `/` (home). Domain methods return Result<void, String> for layouts to handle errors. For profile completion flows, call `authDomain.refreshAuthState()` after saving data to trigger navigation via the router.
- **FOMO (Follow Original Method Ordering)**:
  - See `fomo.md` for detailed method ordering rules for both widget and non-widget classes.

## Code Formatting Policy
**CRITICAL RULE - Automatic Formatting**: After creating any new Dart file or making changes to existing Dart files, ALWAYS run `dart format .` command to ensure consistent code formatting. This must be done before presenting changes to the user. The dart formatter enforces the 80-character line limit and consistent style across the codebase. Always format code at the end of all file changes before presenting results.

## Commit & Push Policy
**Critical Rule**:
- Never commit/push automatically.
- Always: finish work → run tests → present changes → wait for explicit approval.
- No exceptions, even for urgent fixes.  

---

## Notes
- Always end new files with a newline.  