exports.config =

  modules:
    definition: false
    wrapper: (path, data) ->
      unless path.match /^wrappers/
        "(function() {\n#{data}\n})();\n\n"
      else
        data

  paths:
    public: "lib/"
    watched: ['src', 'wrappers', 'test', 'vendor']

  sourceMaps: true

  files:
    javascripts:
      joinTo: 
        'neck.js': /^(src|wrappers)/
        'test/vendor.js': /^(test(\/|\\)(?=vendor)|bower_components)/
        'test/test.js': /^test(\/|\\)spec/
      order:
        before: [
          'test/vendor/jquery-2.0.3.js'
          'test/vendor/mocha-1.14.0.js'
          'bower_components/underscore/underscore.js'
          'wrappers/prefix.js'
          'src/neck.coffee'
          'src/modules/controller.coffee'
          'src/modules/helper.coffee'
          'src/modules/router.coffee'
          'src/modules/app.coffee'
        ]
        after: [
          'wrappers/suffix.js'
        ]

    stylesheets:
      joinTo: 
        'test/style.css': /^test/

  plugins:
    javascript:
      validate: false
