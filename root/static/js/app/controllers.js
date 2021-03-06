/*
 * Judoon
 * https://judoon.org/
 * https://github.com/Judoon/judoon.git
 *
 * Author:    Fitz ELLIOTT <felliott@fiskur.org>
 * Copyright: 2014 by the Rector and Visitors of the University of Virginia.
 * License:   Artistic License 2.0 (GPL Compatible)
 */

/*jshint globalstrict: true */
/*jshint jquery: true */
/*global angular, Handlebars, window */

'use strict';

var judoonCtrl = angular.module('judoon.controllers', ['ngSanitize']);

judoonCtrl.controller(
    'UserCtrl',
    ['$scope', '$location', '$modal', 'user', 'Alerts',
     function ($scope, $location, $modal, user, Alerts) {

         $scope.alerter = Alerts;
         $scope.user    = user;

         $scope.$on('UserDatasetCtrl::deleteThisDataset', function(event, dataset) {
             $scope.user.deleteDataset(dataset).then(
                 function() { Alerts.alertSuccess("Dataset '" + dataset.name + "' deleted!");     },
                 function() { Alerts.alertError('Something went wrong!'); }
             );
         });

         $scope.openHowTo = function() {
            $modal.open({
                templateUrl: 'whatnow.html',
                controller: 'WhatNowCtrl'
            });
         };


         // support hash-linking of tabs
         var hashPrefix          = "dataset";
         var ignoreNextUpdateUrl = 1;
         var ignoreNextUpdateTab = 0;
         $scope.$watch('user.datasetsLoaded', function() {
             if (user.datasetsLoaded) {
                 updateTabFromUrl();
             }
         });
         $scope.$on('$routeUpdate', function() {
             updateTabFromUrl();
         });

         function updateTabFromUrl() {
             if (ignoreNextUpdateTab) {
                 ignoreNextUpdateTab = 0;
                 return;
             }
             var hashId = hashToId();
             if (!hashId) {
                 return;
             }
             angular.forEach($scope.user.datasets, function(value) {
                 value.tabActive = value.id == hashId ? true : false;
             });
             ignoreNextUpdateUrl = 1;
         }


         $scope.updateUrlFromTab = function() {
             if (ignoreNextUpdateUrl) {
                 ignoreNextUpdateUrl = 0;
                 return;
             }
             var selectedDs,
                 hashId = hashToId();
             angular.forEach($scope.user.datasets, function(value) {
                 if (value.tabActive && hashId != value.id) {
                     selectedDs = value;
                 }
             });
             if (selectedDs) {
                 idToHash( selectedDs.id );
             }
             ignoreNextUpdateTab = 1;
         };

         function hashToId()   { return $location.hash().replace(hashPrefix, ''); }
         function idToHash(id) { $location.hash( hashPrefix + id ); }
     }
    ]
);

judoonCtrl.controller(
    'WhatNowCtrl',
    ['$scope', '$modalInstance', function ($scope, $modalInstance) {
        $scope.closeWhatNow = function() { $modalInstance.dismiss(); };
    }]
);


judoonCtrl.controller(
    'UserDatasetCtrl',
    ['$scope', 'Alerts',
     function ($scope, Alerts) {

         $scope.newPage = {type: 'blank', title: 'New Page'};
         $scope.createPage = function() {
             $scope.dataset.createPage($scope.newPage).then(
                 function() { Alerts.alertSuccess('New view added!');     },
                 function() { Alerts.alertError('Something went wrong!'); }
             );
         };

         $scope.deleteThisDataset = function() {
             var confirmed = window.confirm("Are you sure you want to delete this dataset?");
             if (confirmed) {
                 $scope.$emit('UserDatasetCtrl::deleteThisDataset', $scope.dataset);
             }
         };

         $scope.$on('UserPageCtrl::deleteThisPage', function(event, page) {
             $scope.dataset.deletePage(page).then(
                 function() { Alerts.alertSuccess("View '" + page.title + "' deleted!");     },
                 function() { Alerts.alertError('Something went wrong!'); }
             );
         });
     }
    ]
);

judoonCtrl.controller(
    'UserPageCtrl',
    ['$scope', 'Alerts',
     function ($scope, Alerts) {

         if (!$scope.page.columns) {
             $scope.page.getColumns();
         }

         $scope.isActionBlockCollapsed = true;
         $scope.isInfoBlockCollapsed   = true;

         $scope.deleteThisPage = function() {
             var confirmed = window.confirm("Are you sure you want to delete this view?");
             if (confirmed) {
                 $scope.$emit('UserPageCtrl::deleteThisPage', $scope.page);
             }
         };
     }
    ]
);


judoonCtrl.controller(
    'DatasetCtrl',
    ['$scope', '$location', 'user', 'dataset', 'DataType', 'Alerts',
     function ($scope, $location, user, dataset, DataType, Alerts) {

         // *** Alerts ***
         $scope.alerter = Alerts;

         // *** Dataset ***
         $scope.user = user;
         $scope.dataset = dataset;
         $scope.datasetOriginal = angular.copy(dataset);
         $scope.$watch('dataset.columnsLoaded', function() {
             if (!$scope.dataset.columnsLoaded) {
                 return;
             }
             $scope.dsColumnsOriginal = angular.copy($scope.dataset.columns);
         });

         $scope.permissions = [
             {label: 'No',  value: 'private'},
             {label: 'Yes', value: 'public'}
         ];

         $scope.saveDataset = function() {
             $scope.dataset.update()
                 .success( function() { Alerts.alertSuccess('Dataset updated!');    })
                 .error(   function() { Alerts.alertError('Something went wrong!'); });
             $scope.datasetOriginal = angular.copy($scope.dataset);
         };

         $scope.resetDataset = function() {
             $scope.dataset = angular.copy($scope.datasetOriginal);
         };


         // *** Dataset Columns ***
         $scope.saveColumns = function() {
             angular.forEach($scope.dataset.columns, function (value, key) {
                 if (!angular.equals($scope.dsColumnsOriginal[key], value)) {
                     value.update()
                         .success( function() { Alerts.alertSuccess('Dataset column updated!'); })
                         .error(   function() { Alerts.alertError('Something went wrong!');     });
                     $scope.dsColumnsOriginal[key] = angular.copy(value);
                 }
             } );
         };

         $scope.$on('DatasetColumnCtrl::createColumn', function(event, newColumnSpec) {
             $scope.dataset.createColumn(newColumnSpec).then(
                 function() { Alerts.alertSuccess("Column '" + newColumnSpec.new_col_name + "' created!"); },
                 function() { Alerts.alertError('Something went wrong!'); }
             );
         });



         // *** Pages ***
         $scope.allPages = $scope.user.pages;
         $scope.newPage = {type: 'blank', title: 'New View'};
         $scope.createPage = function() {
             $scope.dataset.createPage($scope.newPage)
                 .success( function() { Alerts.alertSuccess('New page added!');    })
                 .error(   function() { Alerts.alertError('Something went wrong!'); });
         };

         $scope.$on('UserPageCtrl::deleteThisPage', function(event, page) {
             $scope.dataset.deletePage(page).then(
                 function() { Alerts.alertSuccess("View '" + page.title + "' deleted!");     },
                 function() { Alerts.alertError('Something went wrong!'); }
             );
         });

         $scope.dataUrl = '/api/datasets/'+$scope.dataset.id+'/data';
         $scope.$watch('dataset.columns', function() {
             $scope.columnDefs = [];
             angular.forEach($scope.dataset.columns, function(value) {
                 $scope.columnDefs.push({
                     sTitle : Handlebars.Utils.escapeExpression(value.name),
                     mData  : Handlebars.compile('{{'+value.shortname+'}}'),
                     sName  : value.shortname,
                     column : value
                 });
             });
         }, true);


         // *** DataTypes ***
         $scope.data_types = DataType.query();


         // *** Tabs ***
         $scope.activeTab = {
             properties : 0,
             data       : 0,
             columns    : 0,
             addColumn  : 0,
             view       : 0
         };

         var hashPrefix          = "";
         var ignoreNextUpdateUrl = 1;
         var ignoreNextUpdateTab = 0;
         updateTabFromUrl();
         $scope.$on('$routeUpdate', function() {
             updateTabFromUrl();
         });

         function updateTabFromUrl() {
             if (ignoreNextUpdateTab) {
                 ignoreNextUpdateTab = 0;
                 return;
             }
             var hashId = hashToId();
             if (!hashId) {
                 return;
             }
             angular.forEach($scope.activeTab, function(value, key) {
                 $scope.activeTab[key] = key == hashId ? true : false;
             });
             ignoreNextUpdateUrl = 1;
         }


         $scope.updateUrlFromTab = function() {
             if (ignoreNextUpdateUrl) {
                 ignoreNextUpdateUrl = 0;
                 return;
             }
             var selectedTab,
                 hashId = hashToId();
             angular.forEach($scope.activeTab, function(value, key) {
                 if (value && hashId != key) {
                     selectedTab = key;
                 }
             });
             if (selectedTab) {
                 idToHash( selectedTab );
             }
             ignoreNextUpdateTab = 1;
         };

         function hashToId()   { return $location.hash().replace(hashPrefix, ''); }
         function idToHash(id) { $location.hash( hashPrefix + id ); }
     }
    ]
);



judoonCtrl.controller(
    'DatasetColumnCtrl',
    ['$scope', 'Lookup', 'Alerts',
     function ($scope, Lookup, Alerts) {

         Lookup.query({}, function (lookups) {
             var self_idx;
             angular.forEach(lookups, function (value, key) {
                 if ((value.group_id === 'internal') && (value.id+"" === $scope.datasetId)) {
                     self_idx = key;
                 }
             });

             lookups.splice(self_idx,1);
             $scope.lookups = lookups;
         });

         $scope.$watch('currentLookup', function vivfyInputs() {
             $scope.thatJoinColumn = null;
             if (!$scope.currentLookup) {
                 return;
             }

             if (!$scope.currentLookup.inputColumnsCanon) {
                 $scope.currentLookup.inputColumnsCanon = Lookup.query({}, {
                     group_id: $scope.currentLookup.group_id,
                     id:       $scope.currentLookup.id,
                     io:       'input'
                 });
             }
         });

         $scope.$watch(
             'currentLookup.inputColumnsCanon',
             function () { filterInputColumns(); },
             true
         );

         $scope.$watch('thatJoinColumn', function vivifyOutputs() {
             $scope.thatSelectColumn = null;
             if (!$scope.thatJoinColumn) {
                 return;
             }

             if (!$scope.thatJoinColumn.outputColumns) {
                 $scope.thatJoinColumn.outputColumns = Lookup.query({}, {
                     group_id: $scope.currentLookup.group_id,
                     id:       $scope.currentLookup.id,
                     io:       'input',
                     input_id: $scope.thatJoinColumn.id,
                     sub_io:   'output'
                 });
             }
         });


         $scope.restrictByType = false;
         $scope.$watch('restrictByType', function () { filterInputColumns(); });
         function filterInputColumns() {
             if (!$scope.currentLookup) {
                 return;
             }

             $scope.currentLookup.inputColumns = [];

             if ($scope.restrictByType) {
                 if (!$scope.thisJoinColumn) {
                     return;
                 }
                 angular.forEach($scope.currentLookup.inputColumnsCanon, function(value) {
                     if (value.type === $scope.thisJoinColumn.data_type) {
                         $scope.currentLookup.inputColumns.push(
                             angular.copy(value)
                         );
                     }
                 });
             }
             else {
                 $scope.currentLookup.inputColumns = angular.copy(
                     $scope.currentLookup.inputColumnsCanon
                 );
             }
         }


         $scope.submitNewColumn = function() {
             var newColumnSpec = {
                 dataset_id:        $scope.datasetId,
                 new_col_name:      $scope.newColumnName,
                 this_table_id:     $scope.datasetId,
                 that_table_id:     $scope.currentLookup.full_id,
                 this_joincol_id:   $scope.thisJoinColumn.shortname,
                 that_joincol_id:   $scope.thatJoinColumn.id,
                 that_selectcol_id: $scope.thatSelectColumn.id
             };
             $scope.$emit('DatasetColumnCtrl::createColumn', newColumnSpec);
         };
     }
    ]
);



judoonCtrl.controller(
    'PageCtrl',
    ['$scope', '$sce', 'user', 'page', 'welcome', '$http', 'Dataset', 'Alerts',
     function ($scope, $sce, user, page, welcome, $http, Dataset, Alerts) {

         // Attributes
         $scope.editmode = 0;
         $scope.alerter = Alerts;
         if (welcome) {
             Alerts.alertSuccess(
                 '<strong>Your dataset has been imported.</strong> ' +
                 'Here is the view we\'ve created for you. ' +
                 'Click <strong>Edit</strong> above to make changes.'
             );
         }

         // TinyMCE
         $scope.tinymce = {
             config: {
                 inline: {
                     inline          : true,
                     schema          : "html5",
                     menubar         : false,
                     plugins         : "paste",
                     paste_as_text   : true,
                     entity_encoding : "raw",
                     toolbar         : "bold italic underline strikethrough subscript superscript removeformat | cut copy pastetext | undo redo",
                     invalid_elements : 'area,audio,canvas,content,data,decorator,element,embed,keygen,main,map,' +
                         'menu,menuitem,object,param,progress,rp,rt,ruby,shadow,source,template,' +
                         'track,video,button,datalist,fieldset,form,input,label,legend,optgroup,' +
                         'option,output,select,textarea,base,link,meta,title,iframe,noscript,script,style,' +
                         'acronym applet basefont bgsound,big,blink,center,dir,font,frame,' +
                         'frameset,hgroup,isindex,listing,marquee,nobr,noframes,plaintext,spacer,' +
                         'strike,tt,xmp,body,head,html,' +

                         'address,article,aside,blockquote,br,caption,col,colgroup,dd,details,' +
                         'div,dl,dt,figcaption,figure,footer,h1,h2,h3,h4,h5,h6,header,hr,img,li,' +
                         'nav,ol,p,pre,section,summary,table,tbody,td,tfoot,th,thead,tr,ul'
                 },
                 block: {
                     inline            : true,
                     schema            : "html5",
                     menubar           : false,
                     forced_root_block : "p",
                     entity_encoding   : "raw",
                     convert_urls      : false,
                     plugins  : "hr link image charmap paste anchor searchreplace table textcolor",
                     toolbar1 : "cut copy pastetext | undo redo | search replace | link unlink anchor | image table hr charmap | numlist bullist outdent indent blockquote",
                     toolbar2 : "bold italic underline strikethrough subscript superscript removeformat | alignleft aligncenter alignright alignjustify | formatselect fontselect fontsizeselect forecolor backcolor",
                     invalid_elements : 'area,audio,canvas,content,data,decorator,element,embed,keygen,main,map,' +
                         'menu,menuitem,object,param,progress,rp,rt,ruby,shadow,source,template,' +
                         'track,video,button,datalist,fieldset,form,input,label,legend,optgroup,' +
                         'option,output,select,textarea,base,link,meta,title,iframe,noscript,script,style,' +
                         'acronym applet basefont bgsound,big,blink,center,dir,font,frame,' +
                         'frameset,hgroup,isindex,listing,marquee,nobr,noframes,plaintext,spacer,' +
                         'strike,tt,xmp,body,head,html'
                 }
             }
         };

         $scope.user = user;
         $scope.page = page;


         $scope.trustTitle     = function() { return $sce.trustAsHtml($scope.page.title);     };
         $scope.trustPreamble  = function() { return $sce.trustAsHtml($scope.page.preamble);  };
         $scope.trustPostamble = function() { return $sce.trustAsHtml($scope.page.postamble); };
         $scope.scrubHtml      = function(text) {
             return String(text).replace(/<(?:.|\n)*?>/gm, '');
         };

         $scope.$watch('page.columnsLoaded', function () {
             if (!$scope.page.columnsLoaded) {
                 return;
             }
             $scope.pageOriginal = angular.copy(page);
             $scope.pageColumnsOriginal = angular.copy(page.columns);
         });

         $scope.$watch('page', function () {
             if (!$scope.page.columnsLoaded) {
                 return;
             }

             $scope.pageDirty = !angular.equals($scope.page, $scope.pageOriginal);
         }, true);


         Dataset.get(page.dataset_id).then( function (dataset) {
             $scope.dataset = dataset;

             $scope.ds_columns = {accessions: [], dict: {}};
             $scope.$watch('dataset.columnsLoaded', function() {
                 if (!$scope.dataset.columnsLoaded) {
                     return;
                 }

                 angular.forEach($scope.dataset.columns, function(value, key) {
                     $scope.ds_columns.dict[value.shortname] = value;
                     if (value.data_type.match(/accession/i)) {
                         $scope.ds_columns.accessions.push(value);
                     }
                 });
             });
         });


         $scope.siteLinker = {};
         $http.get('/api/sitelinker/accession')
             .success(function(data) {
                 angular.forEach(data, function(value) {
                     $scope.siteLinker[value.name] = value;
                 });
             });



         // Methods
         $scope.updatePage = function() {
             if (!$scope.pageDirty) {
                 return;
             }

             if ($scope.page.permission === "public" &&
                 $scope.page.permission !== $scope.pageOriginal.permission) {
                 var confirmed = window.confirm(
                     "Making your view public will make the underlying dataset " +
                         "public, too! Are you sure you want to continue?"
                 );
                 if (!confirmed) {
                     Alerts.alertWarning('Save cancelled.');
                     return;
                 }

             }

             $scope.page.update().success( function() {
                 Alerts.alertSuccess('View saved.');
             });
             $scope.page.updateColumns().success( function() {
                 Alerts.alertSuccess('View columns saved.');
             });
             $scope.pageDirty = 0;
             $scope.pageOriginal = angular.copy($scope.page);
             $scope.pageColumnsOriginal = angular.copy($scope.page.columns);


         };

         $scope.addColumn = function() {
             var newColumn = {title: $scope.newColumnName, template: '', widgets: []};
             $scope.page.columns.push(newColumn);
             $scope.currentColumn = newColumn;
         };

         $scope.removeColumn = function() {
             if (!$scope.deleteColumn) {
                 return;
             }

             var confirmed = window.confirm("Are you sure you want to delete this column?");
             if (confirmed) {
                 if ($scope.deleteColumn === $scope.currentColumn) {
                     $scope.currentColumn = null;
                 }
                 var index = $scope.page.columns.indexOf( $scope.deleteColumn );
                 $scope.page.columns.splice(index, 1);
             }

             return;
         };

         $scope.firstColumn = function() {
             return $scope.page.columns && angular.equals($scope.currentColumn, $scope.page.columns[0]);
         };

         $scope.lastColumn = function() {
             return $scope.page.columns && angular.equals(
                 $scope.currentColumn,
                 $scope.page.columns[ $scope.page.columns.length - 1 ]
             );
         };

         $scope.currentIdx = function() {
             var idx;
             for (idx=0; idx<$scope.page.columns.length; idx++) {
                 if (angular.equals($scope.currentColumn, $scope.page.columns[idx])) {
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
             $scope.page.columns[currentIdx] = $scope.page.columns.splice(
                 currentIdx-1, 1, $scope.page.columns[currentIdx]
             )[0];
         };

         $scope.columnRight = function() {
             if ($scope.lastColumn()) {
                 return;
             }

             var currentIdx = $scope.currentIdx();
             $scope.page.columns[currentIdx] = $scope.page.columns.splice(
                 currentIdx+1, 1, $scope.page.columns[currentIdx]
             )[0];
         };


         $scope.isBold   = curryFormatTest('bold');
         $scope.isItalic = curryFormatTest('italic');
         function curryFormatTest(format) {
             return function(widget) {
                 return widget && widget.formatting && widget.formatting.some(function(e) { return e === format; });
             };
         }

         $scope.columnIsActive = function(column) {
             return $scope.editmode &&
                 angular.equals(column, $scope.currentColumn);
         };
         $scope.columnIsDelete = function(column) {
             return $scope.editmode &&
                 angular.equals(column, $scope.deleteColumn);
         };

         $scope.$watch('currentColumn.widgets', function() {
             if (!$scope.currentColumn) {
                 return;
             }
             $http.post('/api/template', {widgets: $scope.currentColumn.widgets})
                 .success(function(data) {
                     $scope.currentColumn.template = data.template;
                 })
                 .error(function() {
                     Alerts.alertError('Unable to translate template!');
                 });
         }, true);


         $scope.curriedRenderTmpl = function(idx) {
             var renderTmpl = function(dataSource, callType) {
                 return $scope.compiledTmpls[idx](dataSource);
             };
             return renderTmpl;
         };

         $scope.getSortColumn = function(widgets) {
             var sortVal = [];
             angular.forEach(widgets, function(widget) {
                 if (widget.type === 'variable') {
                     sortVal.push(widget.name);
                 }
                 else if (widget.type === 'link') {
                     if (widget.url.variable_segments[0]) {
                         sortVal.push(widget.label.variable_segments[0]);
                     }
                 }
             });
             return sortVal.join('|');
         };

         $scope.dataUrl = '/api/datasets/'+$scope.page.dataset_id+'/data';
         $scope.$watch('page.columns', function() {
             $scope.compiledTmpls = [];
             $scope.columnDefs    = [];
             angular.forEach($scope.page.columns, function(value, key) {
                 $scope.compiledTmpls.push( Handlebars.compile(value.template) );
                 $scope.columnDefs.push({
                     sTitle : value.title,
                     sName  : $scope.getSortColumn(value.widgets),
                     mData  : $scope.curriedRenderTmpl(key),
                     column : value
                 });
             });
         }, true);


     }]);



judoonCtrl.controller(
    'PageColumnTemplateCtrl',
    ['$scope', '$modal', function ($scope, $modal) {

        $scope.$watch('currentColumn', function() {
            if (!$scope.currentColumn) {
                return;
            }
            $scope.cursorWidget = $scope.currentColumn.widgets[ $scope.currentColumn.widgets.length - 1];
        });

        /*
          The cursor is positioned after $scope.cursorWidget in the
          list of widgets. In order to position the cursor at the
          beginning of the list, the column widgets are indexed using a
          one-based indexing.  Index 0 is the beginning of the
          list. Index 1 is the first widget in the list.
        */
        $scope.getCursorIndex = function() {
            return !($scope.cursorWidget && $scope.currentColumn.widgets.length) ? 0
                : $scope.$parent.currentColumn.widgets.indexOf( $scope.cursorWidget ) + 1;
        };

        $scope.cursorBack = function() {
            var cursorIdx = $scope.getCursorIndex();
            $scope.cursorWidget = cursorIdx < 2 ? null
                : $scope.currentColumn.widgets[cursorIdx-2];
            return;
        };

        $scope.cursorForward = function() {
            var widgetCount = $scope.currentColumn.widgets.length;
            if (!widgetCount) {
                return;
            }

            var cursorIdx = $scope.getCursorIndex();
            if (cursorIdx < widgetCount) {
                $scope.cursorWidget = $scope.currentColumn.widgets[cursorIdx];
            }

            return;
        };

        function addNode(node) {
            var index = $scope.getCursorIndex();
            $scope.currentColumn.widgets.splice(index, 0, node);
            $scope.cursorWidget = $scope.currentColumn.widgets[index];
            return;
        }
        $scope.addTextNode = function() {
            addNode({type: 'text', value: '', formatting: []});
        };

        $scope.addDataNode = function() {
            addNode({type: 'variable', name: '', formatting: []});
        };

        $scope.addNewlineNode = function() {
            addNode({type: 'newline'});
        };

        $scope.addLinkNode = function() {
            addNode({
                type: 'link',
                formatting: [],
                url: {
                    type:              "varstring",
                    varstring_type:    "variable",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                },
                label: {
                    type:              "varstring",
                    varstring_type:    "static",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                }
            });
        };

        $scope.addImageNode = function() {
            addNode({
                type: 'image',
                url: {
                    type:              "varstring",
                    varstring_type:    "variable",
                    accession:         "",
                    text_segments:     [],
                    variable_segments: [],
                    formatting:        []
                }
            });
        };

        $scope.removeNodeAtCursor = function() {
            var index = $scope.getCursorIndex();
            if (!index) {
                return;
            }

            $scope.cursorBack();
            $scope.currentColumn.widgets.splice(index-1, 1);
            return;
        };

        $scope.removeNode = function(widget) {
            var index = $scope.currentColumn.widgets.indexOf(widget);
            if (widget === $scope.cursorWidget) {
                $scope.cursorBack();
            }
            $scope.currentColumn.widgets.splice(index, 1);
            return;
        };

        /* Modals */
        $scope.openElementGuide  = function() {
            $modal.open({
                templateUrl: 'elementGuide.html',
                controller: 'ElementGuideCtrl'
            });
        };

        $scope.previewUrl = function(widget) {
            return zipSegments(widget.url);
        };

        $scope.previewLabel = function(widget) {
            return zipSegments(widget.label);
        };

        function zipSegments(varstring) {
            var maxlen = Math.max(
                varstring.text_segments.length,
                varstring.variable_segments.length
            );

            var retstring = '';
            for (var i = 0; i < maxlen; i++) {
                retstring += varstring.text_segments[i] || '';
                retstring += getSampleData(varstring.variable_segments[i]);
            }
            return retstring;
        }

        function getSampleData(colname) {
            return $scope.ds_columns.dict[colname].sample_data[0] || '';
        }
    }]
);



judoonCtrl.controller(
    'ElementGuideCtrl',
    ['$scope', '$modalInstance', function ($scope, $modalInstance) {
        $scope.closeElementGuide = function() { $modalInstance.dismiss(); };
    }]
);



judoonCtrl.controller(
    'LinkBuilderCtrl',
    ['$scope', '$modalInstance', 'currentLink', 'columns', 'siteLinker',
     function ($scope, $modalInstance, currentLink, columns, siteLinker) {

         $scope.columns = columns;
         $scope.url = {
             active: {
                 accession : currentLink.url.varstring_type === 'accession' ? true : false,
                 fromdata  : currentLink.url.varstring_type === 'variable'  ? true : false,
                 fixed     : currentLink.url.varstring_type === 'static'    ? true : false
             },
             accession: { site: '', source: ''},
             fromdata:  { prefix: '', variable: '', suffix: ''},
             fixed:     ''
         };
         if ($scope.url.active.accession) {
             $scope.url.accession.site   = currentLink.url.accession;
             $scope.url.accession.source = currentLink.url.variable_segments[0];
         }
         else if ($scope.url.active.fromdata) {
             $scope.url.fromdata.prefix   = currentLink.url.text_segments[0];
             $scope.url.fromdata.variable = currentLink.url.variable_segments[0];
             $scope.url.fromdata.suffix   = currentLink.url.text_segments[1] || '';
         }
         else {
             $scope.url.fixed = currentLink.url.text_segments[0];
         }


         $scope.label = {
             type     : currentLink.label.varstring_type,
             fixed    : '',
             fromdata : { prefix: '', variable: '', suffix: ''}
         };
         if ($scope.label.type === 'static') {
             $scope.label.fixed = currentLink.label.text_segments[0] || getLabelDefault();
         }
         else {
             $scope.label.fromdata.prefix   = currentLink.label.text_segments[0];
             $scope.label.fromdata.variable = currentLink.label.variable_segments[0];
             $scope.label.fromdata.suffix   = currentLink.label.text_segments[1] || '';
         }

         function getLabelDefault() {
             return $scope.url.active.accession && $scope.url.accession.site ?
                 getCurrentSite().label : 'Link';
         }


         $scope.$watch('url.accession.source', function() {
             $scope.linkSites = getLinkableSites();
         }, true);


         $scope.labelPreview = '';
         function updateLabelPreview() {
             switch ($scope.label.type) {
             case 'default':
                 $scope.labelPreview = getLabelDefault();
                 break;
             case 'url':
                 $scope.labelPreview = $scope.urlPreview;
                 break;
             case 'variable':
                 $scope.labelPreview = $scope.label.fromdata.prefix +
                     getSampleData($scope.label.fromdata.variable) +
                     $scope.label.fromdata.suffix;
                 break;
             case 'static':
                 $scope.labelPreview =  $scope.label.fixed;
                 break;
             }
         }
         $scope.$watch('label', function() { updateLabelPreview(); }, true);

         $scope.urlPreview = '';
         function updateUrlPreview() {
             if ($scope.url.active.fixed) {
                 $scope.urlPreview = $scope.url.fixed;
             }
             else if ($scope.url.active.accession) {
                 if (!$scope.url.accession.site) {
                     $scope.urlPreview = '';
                 }
                 else {
                     var accession_parts = getUrlPartsForCurrentSite();
                     $scope.urlPreview = accession_parts.prefix +
                         getSampleData($scope.url.accession.source) +
                         accession_parts.suffix;
                 }
             }
             else if ($scope.url.active.fromdata) {
                 $scope.urlPreview = $scope.url.fromdata.prefix +
                     getSampleData($scope.url.fromdata.variable) +
                     $scope.url.fromdata.suffix;
             }
         }
         $scope.$watch('url', function() {
             updateUrlPreview();
             updateLabelPreview();
         }, true);


         function getSampleData(colname) {
             if (!colname) {
                 return '';
             }
             return columns.dict[colname].sample_data[0];
         }
         function getDataType(colname)   {
             return columns.dict[colname].data_type;
         }


         function getLinkableSites() {
             if (!$scope.url.accession.source) {
                 return [];
             }
             return siteLinker[getDataType($scope.url.accession.source)].sites;
         }
         function getCurrentSite() {
             var site;
             angular.forEach(getLinkableSites(), function(value) {
                 if (value.name === $scope.url.accession.site) {
                     site = value;
                 }
             });
             return site;
         }
         function getUrlPartsForCurrentSite()  {
             return getCurrentSite().mapping;
         }


         $scope.closeLinkBuilder = function() {
             $modalInstance.dismiss('cancel');
             return false;
         };

         $scope.saveWidget = function() {

             var url;
             if ($scope.url.active.fixed) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fixed],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.url.active.fromdata) {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fromdata.prefix, $scope.url.fromdata.suffix],
                     variable_segments: [$scope.url.fromdata.variable],
                     varstring_type:    'variable'
                 };
             }
             else if ($scope.url.active.accession) {
                 var urlParts = getUrlPartsForCurrentSite();
                 url = {
                     accession:         $scope.url.accession.site,
                     text_segments:     [urlParts.prefix, urlParts.suffix],
                     variable_segments: [$scope.url.accession.source],
                     varstring_type:    'accession'
                 };
             }

             var label;
             if ($scope.label.type === 'default') {
                 label = {
                     text_segments:     [getLabelDefault()],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.label.type === 'static') {
                 label = {
                     text_segments:     [$scope.label.fixed],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.label.type === 'url') {
                 label = angular.copy(url);
                 label.varstring_type = label.variable_segments.length ? 'variable' : 'static';
             }
             else if ($scope.label.type === 'variable') {
                 label = {
                     text_segments:     [$scope.label.fromdata.prefix, $scope.label.fromdata.suffix],
                     variable_segments: [$scope.label.fromdata.variable],
                     varstring_type:    'variable'
                 };
             }
             label.accession = '';

             $modalInstance.close({url: url, label: label});
             return false;
         };
     }]
);


judoonCtrl.controller(
    'ImageBuilderCtrl',
    ['$scope', '$modalInstance', 'currentImage', 'columns',
     function ($scope, $modalInstance, currentImage, columns) {

         $scope.columns = columns;
         $scope.url = {
             type: currentImage.url === 'static' ? 'fixed' : 'fromdata'
         };
         if ($scope.url.type === 'fixed') {
             $scope.url.fixed = currentImage.url.text_segments[0];
         }
         else {
             $scope.url.fromdata = {
                 prefix:     currentImage.url.text_segments[0] || '',
                 datasource: currentImage.url.variable_segments[0] || '',
                 suffix:     currentImage.url.text_segments[1] || ''
             };
         }

         function updateSampleUrl() {
             if ($scope.url.type === 'fixed') {
                 $scope.sampleUrl = $scope.url.fixed;
             }
             else if ($scope.url.type === 'fromdata') {
                 if (!$scope.url.fromdata.datasource) {
                     $scope.sampleUrl = '';
                 }
                 else {
                     $scope.sampleUrl = $scope.url.fromdata.prefix +
                         columns.dict[$scope.url.fromdata.datasource].sample_data[0] +
                         $scope.url.fromdata.suffix;
                 }
             }
         }
         $scope.$watch('url', function() { updateSampleUrl(); }, true);

         $scope.closeImageBuilder = function() {
             $modalInstance.dismiss('cancel');
             return false;
         };

         $scope.saveWidget = function() {
             var url;
             if ($scope.url.type === 'fixed') {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fixed],
                     variable_segments: [],
                     varstring_type:    'static'
                 };
             }
             else if ($scope.url.type === 'fromdata') {
                 url = {
                     accession:         '',
                     text_segments:     [$scope.url.fromdata.prefix, $scope.url.fromdata.suffix],
                     variable_segments: [$scope.url.fromdata.datasource],
                     varstring_type:    'variable'
                 };
             }

             $modalInstance.close({url: url});
             return false;
         };
     }]
);
