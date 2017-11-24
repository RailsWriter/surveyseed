angular.module('home', []).controller('home', function($scope, $http) {
	console.log("redeem::"+$scope.redeem)
	console.log("contactFreq::"+$scope.contactFreq)
	console.log("userId::"+$scope.userId)
	$scope.barData = [
		['Genre', 'Completed', 'Attempted',  {role: 'annotation'}],
		['Aug 2016', 1000, 2544, ''],
		['Sep 2016', 16002, 22119, ''],
		['Oct 2016', 28005, 19006, '']
	];

	$http({method: 'GET', url: 'https://www.ketsci.com/users/surveyStats?userRecordId='+$scope.userId}).
	then(function(response) {
		console.log("user panel stats::111::"+JSON.stringify(response,null,'  '));
		// Load the Visualization API and the corechart package.
		google.charts.load('current', {'packages':['corechart']});

		// Set a callback to run when the Google Visualization API is loaded.
		google.charts.setOnLoadCallback(drawChart);

		console.log("user panel stats::"+response.data);
  /*      var barData =[
                        ['Genre','Completed',{'role': 'annotation'}],
                        ['2017-03',1,'']
                    ];*/
        var barData = response.data
        var completedSurveys = 0;
        for(row in barData){
            if(row > 0){
                completedSurveys = completedSurveys + barData[row][1];
            }
        }
        console.log("completedSurveys::"+completedSurveys);
        $scope.completedSurveys=completedSurveys;
		$scope.barData = barData;
//        $scope.barData = [
//		['Genre', 'Completed',  {role: 'annotation'}],
//		['Aug 2016', 1000, ''],
//		['Sep 2016', 16002, ''],
//		['Oct 2016', 28005, '']
//	];
	}, function(response) {
		// Load the Visualization API and the corechart package.
		google.charts.load('current', {'packages':['corechart']});

		// Set a callback to run when the Google Visualization API is loaded.
		google.charts.setOnLoadCallback(drawChart);

		$scope.data = response.data || "Request failed";
		$scope.status = response.status;
	});
	
	$scope.unsubscribeSurvey = function(){
		var prefs = {}
		prefs.preferences = {
				userId : $scope.userId,
				surveyFrequency : "0"
			}

		console.log("model data::"+$scope.contactFreq)
		console.log("prefs::"+JSON.stringify(prefs,null,'  '));
		$http.post('https://www.ketsci.com/users/savePreferences', prefs).success(function(data) {
			console.log("Successfully saved user preferences");
		}).error(function() {
			console.log('Unable to save preferences');
		});	
	}
	
	$scope.saveUserPrefs = function(){
         $scope.cancel_prefs=false
		var prefs = {}
		prefs.preferences = {
				userId : $scope.userId,
				redeemRewards : $scope.redeem,
				surveyFrequency : $scope.contactFreq
			}

		console.log("model data::"+$scope.contactFreq)
		console.log("prefs::"+JSON.stringify(prefs,null,'  '));
		$http.post('https://www.ketsci.com/users/savePreferences', prefs).success(function(data) {
            $scope.save_prefs=true
			console.log("Successfully saved user preferences");
		}).error(function() {
             $scope.save_prefs_error=true
			console.log('Unable to save preferences');
		});	
	}

    $scope.cancelPrefs = function(){
        $scope.save_prefs=false
        $scope.save_prefs_error=false
        $scope.cancel_prefs=true
	}
    
    $scope.removeSavePrefAlert = function(){
        $scope.save_prefs=false
        $scope.save_prefs_error=false
    }
    
    $scope.removeCancelAlert = function(){
         $scope.cancel_prefs=false
    }
	function drawChart() {
/*
		var barData = google.visualization.arrayToDataTable([
			['Genre', 'Completed', 'Attempted',  {role: 'annotation'}],
			['Aug 2016', 1000, 2544, ''],
			['Sep 2016', 16002, 22119, ''],
			['Oct 2016', 28005, 19006, '']
		]);
*/
        console.log("barDatca::"+JSON.stringify($scope.barData,null,' '));
        var barData = google.visualization.arrayToDataTable($scope.barData);
		/*var barData = google.visualization.arrayToDataTable([
                        ['Genre','Completed',{'role': 'annotation'}],
                        ['2017-03',1,'']
                    ]);*/
		var view = new google.visualization.DataView(barData);
		view.setColumns([0, 1,
			{
				calc: "stringify",
				sourceColumn: 1,
				type: "string",
				role: "annotation"
			}]);

		var options = {
			//title: "Credits earned so far",
			width: 600,
			height: 400,
			bar: {groupWidth: "65%"},
			legend: {position: "top"},
		};
		var chart = new google.visualization.ColumnChart(document.getElementById("creditsChart"));
		chart.draw(view, options);
	}
});