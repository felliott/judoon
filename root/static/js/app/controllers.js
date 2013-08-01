'use strict';

var judoonCtrl = angular.module('judoon.controllers', []);

judoonCtrl.controller(
    'DatasetCtrl',
    ['$scope', '$routeParams', '$http', 'Dataset', 'DatasetColumn', 'DatasetPage',
     function ($scope, $routeParams, $http, Dataset, DatasetColumn, DatasetPage) {

         // *** View property defaults
         $scope.hideProperties = false;
         $scope.hideData       = true;
         $scope.hideColumns    = true;
         $scope.hidePages      = true;


         // *** Alerts ***
         $scope.alerts = [];
         $scope.addAlert = function(type, msg) {
             $scope.alerts.push({type: type, msg: msg});
         };
         $scope.closeAlert = function(index) {
             $scope.alerts.splice(index, 1);
         };


         // *** Dataset ***
         $scope.userName  = $routeParams.userName;
         $scope.datasetId = $routeParams.datasetId;
         Dataset.get({id: $scope.datasetId}, function (dataset) {
             $scope.datasetOriginal = angular.copy(dataset);
             $scope.dataset = dataset;
         });

         $scope.permissions = [
             {label: 'No', value: 'private'},
             {label: 'Yes', value: 'public'}
         ];

         $scope.saveDataset = function() {
             Dataset.update(
                 {}, {
                     id:         $scope.datasetId,
                     name:       $scope.dataset.name,
                     notes:      $scope.dataset.notes,
                     permission: $scope.dataset.permission
                 },
                 function() { $scope.addAlert('success', 'Dataset updated!'); },
                 function() { $scope.addAlert('error', 'Something went wrong!'); }
             );
             $scope.datasetOriginal = $scope.dataset;
         };

         $scope.resetDataset = function() {
             $scope.dataset = angular.copy($scope.datasetOriginal);
         };


         // *** Dataset Columns ***
         DatasetColumn.query({}, {dataset_id: $scope.datasetId}, function (columns) {
             $scope.dataset.columns = columns;
             $scope.dsColumnsLoaded = 1;
         });


         // *** Pages ***
         DatasetPage.query({}, {dataset_id: $scope.datasetId}, function (pages) {
             $scope.dataset.pages = pages;
         });

         $scope.newPage = {type: 'blank'};
         $scope.createPage = function() {
             DatasetPage.create({}, $scope.newPage);
         };


         $scope.getServerData = function ( sSource, aoData, fnCallback ) {
             $.ajax( {
                 "dataType" : "json",
                 "type"     : "GET",
                 "url"      : sSource,
                 "data"     : aoData,
                 "success": [
                     function(data) {
                         var new_data = [];
                         for (var i = 0; i < data.tmplData.length; i++) {
                             new_data[i] = [];
                             for (var j = 0; j < $scope.dataset.columns.length; j++) {
                                 new_data[i][j] = data.tmplData[i][$scope.dataset.columns[j].shortname];
                             }
                         }
                         data.aaData = new_data;
                     },
                     fnCallback
                 ],
             } );
         };

     }
    ]
);



judoonCtrl.controller('PageCtrl', ['$scope', '$routeParams', 'Page', 'PageColumn', 'Dataset', function ($scope, $routeParams, Page, PageColumn, Dataset) {

    // Attributes
    $scope.editmode = 0;

    $scope.userName = $routeParams.userName;
    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    Page.get({id: $scope.pageId}, function (page) {
        $scope.pageOriginal = angular.copy(page);
        $scope.page = page;
        $scope.pageLoaded = 1;
        Dataset.get({id: page.dataset_id}, function (ds) {
            $scope.dataset = ds;
        });
    });

    $scope.$watch('page', function () {
        $scope.pageDirty = !angular.equals($scope.page, $scope.pageOriginal);
    }, true);


    $scope.newColumnName;
    $scope.currentColumn;
    $scope.deleteColumn;
    PageColumn.query({}, {page_id: $scope.pageId}, function (columns) {
        $scope.pageColumnsOriginal = angular.copy(columns);
        $scope.pageColumns = columns;
        $scope.pageColumnsLoaded = 1;
    });
    $scope.$watch('pageColumns', function () {
        $scope.pageDirty = !angular.equals($scope.pageColumns, $scope.pageColumnsOriginal);
    }, true);


    // Methods
    $scope.updatePage = function() {
        if (!$scope.pageDirty) {
            return;
        }

        Page.update({
            id:         $scope.pageId,
            title:      $scope.page.title,
            preamble:   $scope.page.preamble,
            postamble:  $scope.page.postamble,
            dataset_id: $scope.page.dataset_id,
        });

        angular.forEach($scope.pageColumns, function (value, key) {
            PageColumn.update({
                page_id:  value.page_id,
                id:       value.id,
                title:    value.title,
                template: value.template
            });
        } );

        $scope.pageDirty = 0;
        $scope.pageOriginal = angular.copy($scope.page);
        $scope.pageColumnsOriginal = angular.copy($scope.pageColumns);
    };

    $scope.addColumn = function() {
        var newColumn = {
            title: $scope.newColumnName,
            template: '',
            page_id: $scope.pageId
        };

        PageColumn.saveAndFetch(newColumn, function(fullCol) {
            $scope.pageColumns.push(fullCol);
            $scope.currentColumn = fullCol;
        } );
    };

    $scope.removeColumn = function() {
        if (!$scope.deleteColumn) {
            return;
        }

        var confirmed = confirm("Are you sure you want to delete this column?");
        if (confirmed) {
            PageColumn.delete(
                {}, {page_id: $scope.pageId, id: $scope.deleteColumn.id},
                function() {
                    if (angular.equals($scope.currentColumn, $scope.deleteColumn)) {
                        $scope.currentColumn = null;
                    }

                    angular.forEach($scope.pageColumns, function (value, key) {
                        if ( angular.equals(value, $scope.deleteColumn) ) {
                            $scope.pageColumns.splice(key, 1);
                        }
                    } );
                }
            );
        }

        return;
    };

    $scope.firstColumn = function() {
        return $scope.pageColumns && angular.equals($scope.currentColumn, $scope.pageColumns[0]);
    };

    $scope.lastColumn = function() {
        return $scope.pageColumns && angular.equals(
            $scope.currentColumn,
            $scope.pageColumns[ $scope.pageColumns.length - 1 ]
        );
    };

    $scope.currentIdx = function() {
        var idx;
        for (idx=0; idx<$scope.pageColumns.length; idx++) {
            if (angular.equals($scope.currentColumn, $scope.pageColumns[idx])) {
                break;
            }
        }
        return idx;
    };

    $scope.columnLeft = function() {
        if ($scope.firstColumn()) {
            return;
        }

        var currentIdx = $scope.currentIdx();
        $scope.pageColumns[currentIdx] = $scope.pageColumns.splice(
            currentIdx-1, 1, $scope.pageColumns[currentIdx]
        )[0];
    };

    $scope.columnRight = function() {
        if ($scope.lastColumn()) {
            return;
        }

        var currentIdx = $scope.currentIdx();
        $scope.pageColumns[currentIdx] = $scope.pageColumns.splice(
            currentIdx+1, 1, $scope.pageColumns[currentIdx]
        )[0];
    };


    $scope.getServerData = function ( sSource, aoData, fnCallback ) {
        $.ajax( {
            "dataType": "json",
            "type": "GET",
            "url": sSource,
            "data": aoData,
            "success": [
                function(data) {
                    var templates = [];
                    angular.forEach($scope.pageColumns, function (value, key) {
                        templates.push( Handlebars.compile(value.template) );
                    } );

                    var new_data = [];
                    for (var i = 0; i < data.tmplData.length; i++) {
                        new_data[i] = [];
                        for (var j = 0; j < templates.length; j++) {
                            new_data[i][j] = templates[j](data.tmplData[i]);
                        }
                    }
                    data.aaData = new_data;
                },
                fnCallback
            ],
        } );
    };

}]);


judoonCtrl.controller('DatasetColumnCtrl', ['$scope', '$routeParams', 'Dataset', 'DatasetColumn', 'Transform', '$window', function ($scope, $routeParams, Dataset, DatasetColumn, Transform, $window) {

    $scope.userName  = $routeParams.userName;
    $scope.datasetId = $routeParams.datasetId;
    DatasetColumn.query({},{dataset_id: $scope.datasetId}, function (columns) {
        $scope.dsColumnsOriginal = angular.copy(columns);
        $scope.dsColumns = columns;
    });

    Transform.query({}, function(transformTypes) {
        $scope.transformTypes = transformTypes;
        $scope.transformTypes.unshift({
            name: 'Join Table',
            id:   'join',
            transforms: [
                {
                    name:    'JoinTable',
                    id:      'join',
                    accepts: 'any',
                    module:  'Accession::JoinTable'
                }

            ],
            constraint: function() { return 1; }
        });
    });

    $scope.$watch('transformType', function() {
        if (
            (!$scope.transformType)
              ||
            ($scope.transformType.id === 'join')
              ||
            ($scope.transformType.transforms)
        ) {
            return;
        }

        Transform.query({}, {id: $scope.transformType.id}, function(transforms) {
            $scope.transformType.transforms = transforms;
        });
    });

    Dataset.query({}, function (datasets) {
        $scope.myDatasets = datasets;
        angular.forEach(datasets, function(value, key) {
            if (value.id == $scope.datasetId) {
                $scope.myDatasets.splice(key, 1);
                return;
            }

            DatasetColumn.query({}, {dataset_id: value.id}, function (columns) {
                value.columns = columns;
            });
        });
    });

    $scope.submitNewColumn = function() {
        var data;

        if ($scope.transform.id === 'join') {
            data = {
                name:         $scope.newColumnName,
                module:       $scope.transform.module,
                dataset_id:   $scope.datasetId,
                input_field:  $scope.sourceColumn.shortname,
                join_dataset: $scope.joinDataset.id,
                join_column:  $scope.joinColumn.shortname,
                to_column:    $scope.outputColumn.shortname
            };
        }
        else {
            data = {
                name:          $scope.newColumnName,
                module:        $scope.transform.module,
                dataset_id:    $scope.datasetId,
                input_field:   $scope.sourceColumn.shortname,
                input_format:  $scope.inputType,
                output_format: $scope.outputType
            };
        }

        DatasetColumn.save({}, data);
        $window.location.reload();
    };

    $scope.$watch('transform', function() {
        $scope.filteredColumns = [];

        if (!$scope.transformType) {
            return;
        }

        angular.forEach($scope.dsColumns, function(value, key) {
            var accepts = $scope.transform.accepts;

            if ((accepts === 'text') && (value.data_type !== 'text')) {
                return;
            }
            if ((accepts === 'accession') && (!value.accession_type)) {
                return;
            }

            $scope.filteredColumns.push(value);
        });
    });

}]);
