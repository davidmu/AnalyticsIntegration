angular
  .module 'analyticsintegration.progress'
  .controller 'ProgressCtrl', ($scope,$timeout, $window) ->
    'use strict'
    $scope.profileId = ""
    $scope.maxWeek = 0
    $scope.currentWeek = 0
    $scope.currentYear = 0
    $scope.maxDay = 0
    $scope.currentDay = 0
    $scope.yesterday = 0
    $scope.width = 0
    $scope.width1 = 0
    $scope.width2 = 0
    CLIENT_ID = '301559273852-uer4kffb02pkb1un8isvcku0igcsuiev.apps.googleusercontent.com'
    SCOPES = ['https://www.googleapis.com/auth/analytics.readonly']
    $scope.rows = ["hest", "hest1"]
    $scope.todos = JSON.parse($window.localStorage.getItem('todos') or '[]')
    $scope.$watch('todos', (newTodos, oldTodos) ->
      if (newTodos != oldTodos)
        $window.localStorage.setItem 'todos', JSON.stringify(angular.copy($scope.todos))
    , true)

    call1 = {}

    call2 = {}

    $scope.add = ->
      todo = 
        label: $scope.label
        isDone: false
      $scope.todos.push(todo)
      $window.localStorage.setItem 'todos', JSON.stringify(angular.copy($scope.todos))
      $scope.label = ''

    $scope.updatePercentage = ()->
      $scope.width = Math.floor((100*$scope.currentWeek)/$scope.maxWeek)
      $scope.$apply()

    calculateDays = (data)->
      console.log "Days"
      console.log data
      for value, index in data
        console.log(value[3])
        if parseFloat(value[3])>$scope.maxDay
          $scope.maxDay = parseFloat(value[3])
        if index == data.length-1
          $scope.currentDay = parseFloat(value[3])
        if index == data.length-2
          console.log "that was yesterday"
          $scope.yesterday = parseFloat(value[3])
      $scope.width1 = Math.floor((100*$scope.currentDay)/$scope.maxDay)
      $scope.width2 = Math.floor((100*$scope.currentYear)/1500000)
      $scope.$apply()
      $timeout(queryAccounts, 10000)

    updateRows = (data)->
      console.log "ROWS UPDATE"
      $scope.rows = data
      $scope.maxWeek = 0
      $scope.currentWeek = 0
      $scope.currentYear = 0
      for value, index in data
        console.log(value[3])
        if parseFloat(value[3])>$scope.maxWeek
          $scope.maxWeek = parseFloat(value[3])
        $scope.currentYear += parseFloat(value[3])

        if index == data.length-1
          $scope.currentWeek = value[3]
      $scope.updatePercentage()
      console.log $scope.currentWeek,' ', $scope.currentYear,' ', $scope.maxWeek

    $scope.click = ->
      console.log "horse"
      authorize(true)

    authorize = (event)->
      useImmdiate = if event then false else true
      authData = 
        client_id: CLIENT_ID
        scope: SCOPES
        immediate: useImmdiate
      gapi.auth.authorize authData, (response) ->
        if response.error
          #authButton.hidden = false
          console.log response.error
        else
          #authButton.hidden = true
          queryAccounts()
        return
  
    queryAccounts = ->
      # Load the Google Analytics client library.
      gapi.client.load('analytics', 'v3').then ->
        # Get a list of all Google Analytics accounts for this user
        gapi.client.analytics.management.accounts.list().then handleAccounts
        return
      return
  
    handleAccounts = (response) ->
      # Handles the response from the accounts list method.
      if response.result.items and response.result.items.length
        # Get the first Google Analytics account.
        console.log response.result.items
        firstAccountId = response.result.items[1].id
        # Query for properties.
        queryProperties firstAccountId
      else
        console.log 'No accounts found for this user.'
      return

    $scope.numberWithCommas = (x) ->
      return x.toString().replace /\B(?=(\d{3})+(?!\d))/g, ','
    queryProperties = (accountId) ->
      # Get a list of all the properties for the account.
      gapi.client.analytics.management.webproperties.list('accountId': accountId).then(handleProperties).then null, (err) ->
        # Log any errors.
        console.log err
        return
      return
  
    handleProperties = (response) ->
      # Handles the response from the webproperties list method.
      if response.result.items and response.result.items.length
        # Get the first Google Analytics account
        console.log response.result
        firstAccountId = response.result.items[0].accountId
        # Get the first property ID
        firstPropertyId = response.result.items[0].id

        # Query for Views (Profiles).
        queryProfiles firstAccountId, firstPropertyId
      else
        console.log 'No properties found for this user.'
      return
  
    queryProfiles = (accountId, propertyId) ->
      # Get a list of all Views (Profiles) for the first property
      # of the first Account.
      gapi.client.analytics.management.profiles.list(
        'accountId': accountId
        'webPropertyId': propertyId).then(handleProfiles).then null, (err) ->
        # Log any errors.
        console.log err
        return
      return
  
    handleProfiles = (response) ->
      # Handles the response from the profiles list method.
      if response.result.items and response.result.items.length
        # Get the first View (Profile) ID.
        console.log response.result.items
        firstProfileId = response.result.items[0].id
        # Query the Core Reporting API
        $scope.profileId = firstProfileId
        call1 = 
          'ids': 'ga:' + $scope.profileId
          'start-date': '2016-04-01'
          'end-date': 'today'
          'metrics': 'ga:sessions,ga:transactionsPerSession,ga:transactionRevenue'
          'dimensions': 'ga:week'
        call2 = 
          'ids': 'ga:' + $scope.profileId
          'start-date': '2016-04-01'
          'end-date': 'today'
          'metrics': 'ga:sessions,ga:transactionsPerSession,ga:transactionRevenue'
          'dimensions': 'ga:date'
        queryCoreReportingApi firstProfileId, call1
      else
        console.log 'No views (profiles) found for this user.'
      return
  
    queryCoreReportingApi = (profileId) ->
      # Query the Core Reporting API for the number sessions for
      # the past seven days.
      gapi.client.analytics.data.ga.get(call1).then((response) ->
        formattedJson = JSON.stringify(response.result, null, 2)
        console.log response.result
        updateRows(response.result.rows)
        return
      ).then null, (err) ->
        # Log any errors.
        console.log err
        return

      gapi.client.analytics.data.ga.get(call2).then((response) ->
        formattedJson = JSON.stringify(response.result, null, 2)
        console.log response.result
        calculateDays(response.result.rows)
        return
      ).then null, (err) ->
        # Log any errors.
        console.log err
        return
      return