module.exports = (grunt) ->
  config =
    pkg: grunt.file.readJSON 'package.json'
    build_dir: 'bin'
    coffee:
      compile:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: '<%= build_dir %>'
        ext: '.js'
    requirejs:
      production:
        options:
          optimize: 'none'
          baseUrl: '<%= build_dir %>'
          name: '../support/almond'
          include: 'Coffixi/Pixi'
          insertRequire: ['Coffixi/Pixi']
          out: '<%= build_dir %>/pixi.js'
    watch:
      coffee:
        files: '**/*.coffee'
        tasks: 'coffee'
      #requirejs:
      #  files: '<%= build_dir %>/**/*.js'
      #  tasks: 'requirejs'

  ###
  examples = grunt.file.expand
    cwd: 'src/examples'
    filter: (src) ->
      grunt.file.exists "#{src}/main.coffee"
  , '*'
  ###
  ###
  config.requirejs = {}
  for example in examples
    basePath = "#{config.build_dir}/examples/#{example}"
    config.requirejs[example] =
      options:
        baseUrl: basePath
        name: '../../../support/almond'
        include: 'main'
        insertRequire: ['main']
        out: "#{basePath}/main-built.js"
  ###

  grunt.initConfig config

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-requirejs'

  grunt.registerMultiTask 'copyfiles', 'Copy assets into example folders.', ->
    if grunt.file.exists @data.src
      grunt.file.copy @data.src, @data.dest

  grunt.registerTask 'default', ['coffee', 'requirejs']