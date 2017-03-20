angular.module('home', []).controller('home', function($scope, $http) {
	console.log("redeem::"+$scope.redeem)
	console.log("contactFreq::"+$scope.contactFreq)
	console.log("userId::"+$scope.userId)
	$scope.barData = [[]];

	$http({method: 'GET', url: 'https://www.ketsci.com/users/surveyStats?userRecordId='+$scope.userId}).
	then(function(response) {
		console.log("user panel stats::"+response.data);
		$scope.barData = response.data;
		// Load the Visualization API and the corechart package.
		google.charts.load('current', {'packages':['corechart']});

		// Set a callback to run when the Google Visualization API is loaded.
		google.charts.setOnLoadCallback(drawChart);
	}, function(response) {
		// Load the Visualization API and the corechart package.
		google.charts.load('current', {'packages':['corechart']});

		// Set a callback to run when the Google Visualization API is loaded.
		google.charts.setOnLoadCallback(drawChart);

		$scope.data = response.data || "Request failed";
		$scope.status = response.status;
	});

	$scope.saveUserPrefs = function(){
		console.log("model data::"+$scope.contactFreq)
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
		console.log("statsData::"+JSON.stringify($scope.barData))
		var userStats = [['Genre', 'Completed', {role: 'annotation'}]]
		if($scope.barData && $scope.barData.length<=0){
			userStats.push(['2017-01',0,''])
		}else{
			for(i=0;i<$scope.barData.length;i++) {
				$scope.barData[i].push('')
				userStats.push($scope.barData[i])
			}
		}

		console.log("userStats::"+JSON.stringify(userStats))
		var barData = google.visualization.arrayToDataTable(userStats);
		var view = new google.visualization.DataView(barData);
		view.setColumns([0, 1,
			{
				calc: "stringify",
				sourceColumn: 1,
				type: "string",
				role: "annotation"
			},
			2, {
				calc: "stringify",
				sourceColumn: 2,
				type: "string",
				role: "annotation"
			}/*,
			3, {
				calc: "stringify",
				sourceColumn: 3,
				type: "string",
				role: "annotation"
			}*/]);

		var options = {
			title: "Credits earned so far",
			width: 600,
			height: 400,
			bar: {groupWidth: "65%"},
			legend: {position: "top"},
		};
		var chart = new google.visualization.ColumnChart(document.getElementById("creditsChart"));

		chart.draw(view, options);
	}
});