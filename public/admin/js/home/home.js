angular.module('home', ['ui.bootstrap','datamanager']).controller('home', function ($scope, $http, $uibModal,datamanager) {
  /*
   $http.get('/api/v1/auth/bo/user/').success(function(data) {
   $scope.user = data.authId;
   });
   */

  $scope.ageRangeArray = []
  $scope.genderArray=[{name:"Male",selectedValue:"M"},{name:"Female",selectedValue:"F"},{name:"All",selectedValue:"ALL"}]
  $scope.selectedCountry="US"

  $scope.countryList=[]
  $scope.noOfCompletes
  $scope.cpi
  var countryCode;
  var countryList = datamanager.countryList

  for (countryCode in countryList) {
    if (countryList.hasOwnProperty(countryCode)) {
      $scope.countryList.push( {countryCode:countryCode,
        countryName:countryList[countryCode]}
      )
    }
  }
  console.log("$scope.countryList:"+JSON.stringify($scope.countryList,null,'  '))
  $scope.zipArray=[]
  $scope.selectedStatesArray=[]
  $scope.selectedDMAArray=[]

  $scope.selectedStdEduList=[]
  $scope.selectedStdHiUSCodesList=[]
  $scope.selectedChildAgeGenderList=[]
  $scope.selectedStdEmployment=[]

  $scope.updateAge = function () {
    //var ageRangeArray = []
    $scope.currentTemplate='Age'
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'Age'+'Detail.html',
      controller: 'ageModalInstanceCtrl',
      size: 'md',
      resolve: {
        items: function(){
          return $scope.ageRangeArray
        }
      }
    });

    modalInstance.result.then(function () {
    }, function () {
    });
  }

  $scope.updateZip = function () {
    //var ageRangeArray = []
    $scope.currentTemplate='Zip'
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'Zip'+'Detail.html',
      controller: 'zipModalInstanceCtrl',
      size: 'md',
      resolve: {
        items: function(){
          return $scope.zipArray
        }
      }
    });

    modalInstance.result.then(function () {
    }, function () {
    });
  }

  $scope.updateGender = function () {
    $scope.currentTemplate='Gender'
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'Gender'+'Detail.html',
      controller: 'genderModalInstanceCtrl',
      size: 'md',
      resolve: {
        items: function(){
          return $scope.genderArray
        }
      }
    });

    modalInstance.result.then(function () {
    }, function () {
    });
  };

  $scope.updateStates = function () {
    $scope.currentTemplate='States'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'States'+'Detail.html',
      controller: 'statesModalInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {statesArray:datamanager.statesList,
                  country:$scope.selectedCountry,
                  selectedStatesArray:$scope.selectedStatesArray
                }
        }
      }
    });

    modalInstance.result.then(function (selectedStatesArray) {
      $scope.selectedStatesArray=selectedStatesArray
    }, function () {
    });
  };

  $scope.updateDMA = function () {
    $scope.currentTemplate='DMA'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'DMA'+'Detail.html',
      controller: 'dmaModalInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {dmaArray:datamanager.dmaList,
            selectedDMAArray:$scope.selectedDMAArray
          }
        }
      }
    });

    modalInstance.result.then(function (selectedDMAArray) {
      $scope.selectedDMAArray=selectedDMAArray
    }, function () {
    });
  };

  $scope.updateCountry = function(){
    console.log("onChange::selectedCountry::"+$scope.selectedCountry)
    //$('.bfh-select-fix').bfhstates({country:$scope.selectedCountry});
  };

  $scope.toggleAnimation = function () {
    $scope.animationsEnabled = !$scope.animationsEnabled;
  };

  $scope.updateStdChildEdu = function () {
    $scope.currentTemplate='childEdu'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'childEdu'+'Detail.html',
      controller: 'childEduModalInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {stdEduArray:datamanager.stdEduList,
            selectedStdEduList:$scope.selectedStdEduList
          }
        }
      }
    });

    modalInstance.result.then(function (selectedStdEduList) {
      $scope.selectedStdEduList=selectedStdEduList
    }, function () {
    });
  };

  $scope.updateStdHiUS = function () {
    $scope.currentTemplate='HiUS'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'HiUS'+'Detail.html',
      controller: 'childHiUSInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {stdHiUSCodesArray:datamanager.stdHiUSCodesList,
            selectedStdHiUSCodesList:$scope.selectedStdHiUSCodesList
          }
        }
      }
    });

    modalInstance.result.then(function (selectedStdHiUSCodesList) {
      $scope.selectedStdHiUSCodesList=selectedStdHiUSCodesList
    }, function () {
    });
  };

  $scope.updateChildAgeGender = function () {
    $scope.currentTemplate='ChildAgeGender'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'ChildAgeGender'+'Detail.html',
      controller: 'childAgeGenderInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {stdAgeGenderArray:datamanager.ageGenderChildList,
            selectedChildAgeGenderList:$scope.selectedChildAgeGenderList
          }
        }
      }
    });

    modalInstance.result.then(function (selectedChildAgeGenderList) {
      $scope.selectedChildAgeGenderList=selectedChildAgeGenderList
    }, function () {
    });
  };

  $scope.updateStdEmployment = function () {
    $scope.currentTemplate='StdEmployment'
    //console.log("updateStates::selectedCountry::"+JSON.stringify(datamanager,null,'  '))
    var modalInstance = $uibModal.open({
      animation: $scope.animationsEnabled,
      templateUrl: 'edit'+'StdEmployment'+'Detail.html',
      controller: 'stdEmploymentInstanceCtrl',
      size: 'lg',
      resolve: {
        items: function(){
          return {stdEmploymentArray:datamanager.stdEmployment,
            selectedStdEmployment:$scope.selectedStdEmployment
          }
        }
      }
    });

    modalInstance.result.then(function (selectedChildAgeGenderList) {
      $scope.selectedChildAgeGenderList=selectedChildAgeGenderList
    }, function () {
    });
  };

  $scope.saveSurvey = function(){
//    request.send('{ "newAdhocSurvey": { "SurveyName": "acme", "LOI": "12", "TestLink" : "http://..", "LiveLink" : "http://...", "SurveyStillLive" : "false", "Quota" : {"Age" : "["13", "14", "15", "34", "35", "36"]", "Gender" : "1", ... } }');
    var adHocSurvey={}
    var survey = {}
    survey.SurveyName = $scope.survey.name
    survey.TestLink=$scope.survey.testLink
    survey.LiveLink=$scope.survey.liveLink
    survey.LOI=$scope.survey.loi
    var Quotas=[]
    var Quota={
      Age:$scope.ageRangeArray,
      Gender:$scope.genderArray,
      Zip:$scope.zipArray,
      State:$scope.selectedStatesArray,
      Country:$scope.selectedCountry,
      NoOfCompletes:$scope.noOfCompletes,
      CPI:$scope.cpi,
      DMA:$scope.selectedDMAArray,
      childEdu:$scope.selectedStdEduList,
      stdHiUS:$scope.selectedStdHiUSCodesList,
      childAgeGender:$scope.selectedChildAgeGenderList,
      stdEmployment:$scope.selectedStdEmployment
  }
    Quotas.push(Quota)
    survey.Quotas=Quotas
    survey.Question1=$scope.survey.question1
    survey.QuestionAns1=$scope.survey.questionAns1
    survey.Question2=$scope.survey.question2
    survey.QuestionAns2=$scope.survey.questionAns2
    adHocSurvey.newAdhocSurvey=survey
    console.log("survey::"+JSON.stringify(adHocSurvey,null,'  '))

    var headers = {"Content-Type":"application/json"};
    $http({method: "POST", url: "https://ketsci.com/center/draft_survey", data:adHocSurvey, config: headers}).
    then(function(response) {
      console.log('updated survey'+JSON.stringify(response.data))
      $scope.status = response.status;
    }, function(response) {
      $scope.data = response.data || "Request failed";
      $scope.status = response.status;
    });

  }
});

angular.module('home').controller('ageModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance, items) {
  $scope.ageRangeArray = items
  $scope.ok = function () {
    $uibModalInstance.close();
  };

  $scope.addAge = function (){
    var ageRange = []
    for(i=$scope.ageFrom;i<=$scope.ageTo;i++)
      ageRange.push(i)
    console.log('ageRange'+ageRange)
    console.log('ageRangeArray'+ $scope.ageRangeArray )
    $scope.ageRangeArray.push(ageRange)
  };

  $scope.removeAge = function(ageArray){
    var idx = $scope.ageRangeArray.indexOf(ageArray)
    console.log("idx = " + idx)
    $scope.ageRangeArray.splice(idx, 1);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };

});

angular.module('home').controller('zipModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance, items) {
  $scope.zipArray = items
  $scope.ok = function () {
    $uibModalInstance.close();
  };

  $scope.addZip = function (){
    var zipRange = []
    for(i=$scope.zipFrom;i<=$scope.zipTo;i++)
      zipRange.push(i)
    console.log('zipRange'+zipRange)
    console.log('zipArray'+ $scope.zipArray )
    $scope.zipArray.push(zipRange)
  };

  $scope.removeZip = function(zipRange){
    var idx = $scope.zipArray.indexOf(zipRange)
    console.log("idx = " + idx)
    $scope.zipArray.splice(idx, 1);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };

});

angular.module('home').controller('genderModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.genderArray = items
  $scope.ok = function () {
    $uibModalInstance.close();
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };

});

angular.module('home').controller('statesModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  var country="US"
  //console.log("items.selectedCountry::"+JSON.stringify(items.statesArray.statesList[country],null,'  '))
  //$('.bfh-select-fix').bfhstates({country:items.country});
  $scope.selectedStatesArray=items.selectedStatesArray
  var state;
  var stateList = items.statesArray[items.country]
  var finalStateList=[]
  for (state in stateList) {
    if (stateList.hasOwnProperty(state)) {
      finalStateList.push( {stateCode:stateList[state].code,
        stateName:stateList[state].name}
      )
    }
  }
  $scope.statesArray = finalStateList
  console.log("$scope.statesArray::"+JSON.stringify($scope.statesArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedStatesArray::"+$scope.selectedStatesArray)
    $uibModalInstance.close($scope.selectedStatesArray);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };

});

angular.module('home').controller('dmaModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.selectedDMAArray=items.selectedDMAArray
  $scope.dmaArray=items.dmaArray
  console.log("$scope.dmaArray::"+JSON.stringify($scope.dmaArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedDMAArray::"+$scope.selectedDMAArray)
    $uibModalInstance.close($scope.selectedDMAArray);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});

angular.module('home').controller('childEduModalInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.selectedStdEduList=items.selectedStdEduList
  $scope.stdEduArray=items.stdEduArray
  console.log("$scope.stdEduArray::"+JSON.stringify($scope.stdEduArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedStdEduList::"+$scope.selectedStdEduList)
    $uibModalInstance.close($scope.selectedStdEduList);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});

angular.module('home').controller('childHiUSInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.selectedStdHiUSCodesList=items.selectedStdHiUSCodesList
  $scope.stdHiUSCodesArray=items.stdHiUSCodesArray
  console.log("$scope.stdHiUSCodesArray::"+JSON.stringify($scope.stdHiUSCodesArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedStdHiUSCodesList::"+$scope.selectedStdHiUSCodesList)
    $uibModalInstance.close($scope.selectedStdHiUSCodesList);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});

angular.module('home').controller('childAgeGenderInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.selectedChildAgeGenderList=items.selectedChildAgeGenderList
  $scope.stdAgeGenderArray=items.stdAgeGenderArray
  console.log("$scope.stdAgeGenderArray::"+JSON.stringify($scope.stdAgeGenderArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedChildAgeGenderList::"+$scope.selectedChildAgeGenderList)
    $uibModalInstance.close($scope.selectedChildAgeGenderList);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});

angular.module('home').controller('stdEmploymentInstanceCtrl', function ($scope, $http, $compile, $window, $uibModalInstance,items) {
  $scope.selectedStdEmployment=items.selectedStdEmployment
  $scope.stdEmploymentArray=items.stdEmploymentArray
  console.log("$scope.stdEmploymentArray::"+JSON.stringify($scope.stdEmploymentArray,null,'  '))
  $scope.ok = function () {
    console.log("selectedStdEmployment::"+$scope.selectedStdEmployment)
    $uibModalInstance.close($scope.selectedStdEmployment);
  };

  $scope.cancel = function () {
    $uibModalInstance.dismiss('cancel');
  };
});
