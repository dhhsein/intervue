const List<Map<String, String>> kDebriefQuestions = [
  {
    'question':
        'Walk me through what happens, end to end, when a duplicate webhook arrives.',
    'whatToLookFor':
        'They should trace the request through their own code — from the POST endpoint, through Pydantic validation, to the idempotency check (likely a unique constraint or a lookup before insert), and explain what HTTP status code they return and why.',
    'redFlags':
        'Vague answers like "it checks for duplicates." They should know where and how — is it a DB unique constraint? A pre-check query? What\'s the race condition risk?',
  },
  {
    'question':
        'Your database goes down mid-request while saving a session. What does the user\'s system experience? What\'s lost?',
    'whatToLookFor':
        'They should know whether they return a 500, whether the webhook sender would retry, and whether their idempotency logic protects against the retry creating a duplicate once the DB recovers.',
    'redFlags':
        'They haven\'t thought about retries at all, or they assume the DB going down is "handled by SQLAlchemy."',
  },
  {
    'question':
        'Why did you structure your Pydantic model the way you did? Show me a payload that would fail validation and explain why.',
    'whatToLookFor':
        'They should be able to construct a bad payload on the spot — wrong type, missing field, out-of-range value — and explain what Pydantic does with it. Bonus: they mention custom validators and why they added (or chose not to add) them.',
    'redFlags':
        'They only know the happy path. They can\'t articulate why a field is Optional vs required, or what the default values mean.',
  },
  {
    'question':
        'If this service needs to handle 10,000 webhooks per minute, where does your current design break first?',
    'whatToLookFor':
        'Honest identification of bottlenecks — likely the synchronous DB write, connection pool limits, or no queuing layer. Strong candidates will sketch a fix (e.g., async writes, a message queue like SQS, or batching).',
    'redFlags':
        '"It should scale fine" with no reasoning. Or they identify a bottleneck but have no idea how they\'d address it.',
  },
  {
    'question':
        'A second webhook source needs to send sessions in a slightly different payload format. How does your code handle that, and what would you change?',
    'whatToLookFor':
        'This tests whether they designed for extensibility or just solved the immediate problem. Good answers involve payload versioning, a discriminated union model, or a transformation layer before validation.',
    'redFlags':
        '"I\'d just add another endpoint" with no thought about shared logic. Or complete uncertainty about where the change would go.',
  },
  {
    'question':
        'Explain your pagination implementation. What happens if new sessions are inserted between page 1 and page 2 being fetched?',
    'whatToLookFor':
        'They should know whether they used offset-based or cursor-based pagination, and ideally recognize that offset pagination has a consistency problem when new rows are inserted. Strong candidates will name the issue ("page drift") and explain when it matters.',
    'redFlags':
        'They don\'t know what type of pagination they implemented. They\'re unaware of the consistency issue entirely.',
  },
  {
    'question':
        'What does your Dockerfile actually do, line by line? Why did you make those choices?',
    'whatToLookFor':
        'They should be able to explain every instruction — base image choice, why they copy requirements.txt before the rest of the code (layer caching), what the CMD does, and whether they\'re running as a non-root user.',
    'redFlags':
        'They copied a boilerplate Dockerfile and can\'t explain why layers are ordered the way they are. They don\'t know what base image they\'re using.',
  },
  {
    'question':
        'Tell me about one of your tests. Why did you choose to test that specific behavior?',
    'whatToLookFor':
        'They should explain the reasoning behind a test, not just describe what it does. Strong answers reference the risk being mitigated — e.g., "I tested idempotency specifically because a retry storm could corrupt the data." They should also know what\'s not covered and acknowledge it.',
    'redFlags':
        'Tests that only cover the happy path. No ability to explain why a test exists or what failure it prevents.',
  },
  {
    'question':
        'How does your service behave if a field in the incoming JSON is spelled slightly wrong — say user_Id instead of user_id?',
    'whatToLookFor':
        'They should know whether Pydantic is case-sensitive by default (it is), what error gets returned, and whether they\'ve configured any aliases or extra field handling. If they used model_config with extra=\'forbid\' or extra=\'ignore\', they should explain why.',
    'redFlags':
        'They haven\'t tested this and genuinely don\'t know. They assume Pydantic handles it gracefully without knowing what "gracefully" means here.',
  },
  {
    'question':
        'If you had two more hours, what\'s the first thing you\'d add or fix — and what\'s something in here you\'re not happy with?',
    'whatToLookFor':
        'Genuine self-awareness. Real engineers have opinions about their own work. Good answers are specific: "The session model has no index on user_id which would make the GET endpoint slow at scale" or "I used a synchronous SQLAlchemy driver but FastAPI is async — I\'d switch to asyncpg."',
    'redFlags':
        '"I\'m pretty happy with it" or generic answers like "more tests" without specifics. This question separates people who understand what they built from people who just submitted it.',
  },
];

const String kDebriefTip =
    'For questions 2, 5, and 6 — ask them to show you in the code where the behavior occurs as they explain it. Navigation speed and confidence is itself a signal.';
