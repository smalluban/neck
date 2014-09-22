exports.config =

  modules:
    definition: false
    wrapper: false

  paths:
    public: "dist"
    watched: ['src', 'test']

  files:
    javascripts:
      joinTo:
        'neck.js': /^(src|wrappers)/
        'test/vendor.js': /^(test(\/|\\)(?=vendor)|bower_components)/
        'test/test.js': /^test(\/|\\)spec/
      order:
        before: [
          'test/vendor/mocha-1.14.0.js'
          'src/core.coffee'
        ]

    stylesheets:
      joinTo:
        'test/style.css': /^test/
