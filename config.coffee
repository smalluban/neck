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
          'test/vendor/jquery-2.1.1.js'
          'test/vendor/mocha-1.14.0.js'
          'bower_components/underscore/underscore.js'
          'src/neck.coffee'
          'src/modules/controller.coffee'
          'src/modules/helper.coffee'
          'src/modules/router.coffee'
          'src/modules/app.coffee'
        ]

    stylesheets:
      joinTo: 
        'test/style.css': /^test/