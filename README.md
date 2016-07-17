# wwl-js-backbone-extensions

| Current Version | Master | Develop |
|-----------------|--------|---------|
| [![npm version](https://badge.fury.io/js/wwl-js-backbone-extensions.svg)](https://badge.fury.io/js/wwl-js-backbone-extensions) | [![Build Status](https://travis-ci.org/wonderweblabs/wwl-js-backbone-extensions.svg?branch=master)](https://travis-ci.org/wonderweblabs/wwl-js-backbone-extensions) | [![Build Status](https://travis-ci.org/wonderweblabs/wwl-js-backbone-extensions.svg?branch=develop)](https://travis-ci.org/wonderweblabs/wwl-js-backbone-extensions) |

---

# Abstract model


## Usage

```coffeescript
class Article extends require('wwl-js-backbone-extensions').AbstractModel

  rootName: 'article'     # default: 'data'

  # You can combine them:
  jsonOmitted: ['comments']                 # default: []
  jsonPermitted: ['id', 'title', 'rating']  # default: []

  syncWithoutRoot: false  # default: false

  binaryId: true          # default: false

  # You need to implement this
  getRandomBinaryId: ->
    @getOption('context').getSecureRandom().secureHexRandom(128)

  # You need to implement this
  prependedUrlRoot: (url = '') ->
    @context.getUrlHelpers().prependUrlHost(url)

```

```coffeescript
context = your.context.here
model   = new Article({}, { context: context })
```


## Events

```coffeescript

model.on 'before:save', (model, key, val, options) -> #...
model.on 'beforeSync', (method, model, options) -> #...
model.on 'remoteErrors:[...backbone collection events...]', #...
model.on 'dirty:change', (model, dirty) -> # ...

```


## Dirty

Dirty requires the server to send `updated_at` as part of the response. If `updated_at`
changes, the model will be unmarked as dirty.

```coffeescript

model.isDirty() # e.g. false
model.set('name', 'test')
model.isDirty() # e.g. true
model.save()
model.isDirty() # e.g. false

model.isDirty() # e.g. false
model.setDirty()
model.isDirty() # e.g. true
model.setDirty(false)
model.isDirty() # e.g. false

```



## Persistance

```coffeescript

# If it's synced at least once
model.isSynced()

# If it's currently syncing
model.isSyncing()

# If it's a new model
model.isNew()

# Save the model
model.save()

```


## Validations

```coffeescript

# An errors collection for local errors (you need to maintain it by yourself)
model.getLocalErrors()

# An errors collection build by the errors-attribute from the server response.
model.getRemoteErrors()

# If there are local and/or remote errors.
# It calls (backbone feature) the validate function if defined. So you could run your
# local validations there (http://backbonejs.org/#Model-isValid).
model.isValid()

# If there are local errors
model.isLocalValid()

# If there are remote errors
model.isRemoteValid()

# You can run the is...Valid function with one attribute key too, to check just that one.
model.isValid('title')
model.isLocalValid('title')
model.isRemoteValid('title')
```


## Helpers

```coffeescript

# Returns the models sync root name - "data" by default
model.getRootName()

# Returns the meta data sent by the server
model.getMeta()

# Unset all attributes except of the id.
# You can pass { discardId: true } to unset id too.
model.unsetAll()

```

# Abstract collection

```coffeescript

class ArticlesCollection extends require('wwl-js-backbone-extensions').AbstractCollection

  rootName: 'article'     # default: 'data'

  syncWithoutRoot: false  # default: false

  model: Article

  url: '/articles'

  # You need to implement this
  prependedUrl: (url = '') ->
    @context.getUrlHelpers().prependUrlHost(url)

```

```coffeescript
context     = your.context.here
collection  = new ArticlesCollection([], { context: context })
```



## Persistance

```coffeescript

# If it's synced at least once
collection.isSynced()

# If it's currently syncing
collection.isSyncing()

```


## Helpers

```coffeescript

# If there is already the model for the passed id inside the collection, it will return it
# without fetching it - except you're passing true for fetch.
# Attributes will be set to the model
result = collection.getOrFetch(id, attributes = {}, fetch = false)
result.model # the model instance
result.jqxhr # *optional* - the jqxhr request if available

# Returns the model instance (builds it if necessary)
model = collection.getOrInitialize(id, attributes = {}, options = {})

# Returns the models sync root name - "data" by default
collection.getRootName()

# Returns the meta data sent by the server
collection.getMeta()

```

