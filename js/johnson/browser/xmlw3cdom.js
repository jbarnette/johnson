// =========================================================================
//
// xmlw3cdom.js - a W3C compliant W3CDOM parser for XML for <SCRIPT>
//
// version 3.1
//
// =========================================================================
//
// Copyright (C) 2002, 2003, 2004 Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.

// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.

// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// visit the XML for <SCRIPT> home page at xmljs.sourceforge.net
//
// Contains text (used within comments to methods) from the
//  XML Path Language (XPath) Version 1.0 W3C Recommendation
//  Copyright © 16 November 1999 World Wide Web Consortium,
//  (Massachusetts Institute of Technology,
//  European Research Consortium for Informatics and Mathematics, Keio University).
//  All Rights Reserved.
//  (see: http://www.w3.org/TR/2000/WD-W3CDOM-Level-1-20000929/)

/**
 * @function addClass - add new className to classCollection
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  classCollectionStr : string - list of existing class names
 *   (separated and top and tailed with '|'s)
 * @param  newClass           : string - new class name to add
 *
 * @return : string - the new classCollection, with new className appended,
 *   (separated and top and tailed with '|'s)
 */
function addClass(classCollectionStr, newClass) {
  if (classCollectionStr) {
    if (classCollectionStr.indexOf("|"+ newClass +"|") < 0) {
      classCollectionStr += newClass + "|";
    }
  }
  else {
    classCollectionStr = "|"+ newClass + "|";
  }

  return classCollectionStr;
}

/**
 * @class  W3CDOMException - raised when an operation is impossible to perform
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  code : int - the exception code (one of the W3CDOMException constants)
 */
W3CDOMException = function(code) {
  this._class = addClass(this._class, "W3CDOMException");

  this.code = code;
};

// W3CDOMException constants
// Introduced in W3CDOM Level 1:
W3CDOMException.INDEX_SIZE_ERR                 = 1;
W3CDOMException.W3CDOMSTRING_SIZE_ERR             = 2;
W3CDOMException.HIERARCHY_REQUEST_ERR          = 3;
W3CDOMException.WRONG_DOCUMENT_ERR             = 4;
W3CDOMException.INVALID_CHARACTER_ERR          = 5;
W3CDOMException.NO_DATA_ALLOWED_ERR            = 6;
W3CDOMException.NO_MODIFICATION_ALLOWED_ERR    = 7;
W3CDOMException.NOT_FOUND_ERR                  = 8;
W3CDOMException.NOT_SUPPORTED_ERR              = 9;
W3CDOMException.INUSE_ATTRIBUTE_ERR            = 10;

// Introduced in W3CDOM Level 2:
W3CDOMException.INVALID_STATE_ERR              = 11;
W3CDOMException.SYNTAX_ERR                     = 12;
W3CDOMException.INVALID_MODIFICATION_ERR       = 13;
W3CDOMException.NAMESPACE_ERR                  = 14;
W3CDOMException.INVALID_ACCESS_ERR             = 15;


/**
 * @class  W3CDOMImplementation - provides a number of methods for performing operations
 *   that are independent of any particular instance of the document object model.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 */
W3CDOMImplementation = function() {
  this._class = addClass(this._class, "W3CDOMImplementation");
  this._p = null;

  this.preserveWhiteSpace = false;  // by default, ignore whitespace
  this.namespaceAware = true;       // by default, handle namespaces
  this.errorChecking  = true;       // by default, test for exceptions
};


/**
 * @method W3CDOMImplementation.escapeString - escape special characters
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  str : string - The string to be escaped
 *
 * @return : string - The escaped string
 */
W3CDOMImplementation.prototype.escapeString = function W3CDOMNode__escapeString(str) {

  //the sax processor already has this function. Just wrap it
  return __escapeString(str);
};

/**
 * @method W3CDOMImplementation.unescapeString - unescape special characters
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  str : string - The string to be unescaped
 *
 * @return : string - The unescaped string
 */
W3CDOMImplementation.prototype.unescapeString = function W3CDOMNode__unescapeString(str) {

  //the sax processor already has this function. Just wrap it
  return __unescapeString(str);
};

/**
 * @method W3CDOMImplementation.hasFeature - Test if the W3CDOM implementation implements a specific feature
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  feature : string - The package name of the feature to test. the legal only values are "XML" and "CORE" (case-insensitive).
 * @param  version : string - This is the version number of the package name to test. In Level 1, this is the string "1.0".
 *
 * @return : boolean
 */
W3CDOMImplementation.prototype.hasFeature = function W3CDOMImplementation_hasFeature(feature, version) {

  var ret = false;
  if (feature.toLowerCase() == "xml") {
    ret = (!version || (version == "1.0") || (version == "2.0"));
  }
  else if (feature.toLowerCase() == "core") {
    ret = (!version || (version == "2.0"));
  }

  return ret;
};

/**
 * @method W3CDOMImplementation.loadXML - parse XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  xmlStr : string - the XML string
 *
 * @return : W3CDOMDocument
 */
W3CDOMImplementation.prototype.loadXML = function W3CDOMImplementation_loadXML(xmlStr) {
  // create SAX Parser
  var parser;

  try {
    parser = new XMLP(xmlStr);
  }
  catch (e) {
    alert("Error Creating the SAX Parser. Did you include xmlsax.js or tinyxmlsax.js in your web page?\nThe SAX parser is needed to populate XML for <SCRIPT>'s W3C W3CDOM Parser with data.");
  }

  // create W3CDOM Document
  var doc = new W3CDOMDocument(this);

  // populate Document with Parsed Nodes
  this._parseLoop(doc, parser);

  // set parseComplete flag, (Some validation Rules are relaxed if this is false)
  doc._parseComplete = true;

  return doc;
};


/**
 * @method W3CDOMImplementation.translateErrCode - convert W3CDOMException Code
 *   to human readable error message;
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  code : int - the W3CDOMException code
 *
 * @return : string - the human readbale error message
 */
W3CDOMImplementation.prototype.translateErrCode = function W3CDOMImplementation_translateErrCode(code) {
  var msg = "";

  switch (code) {
    case W3CDOMException.INDEX_SIZE_ERR :                // 1
       msg = "INDEX_SIZE_ERR: Index out of bounds";
       break;

    case W3CDOMException.W3CDOMSTRING_SIZE_ERR :            // 2
       msg = "W3CDOMSTRING_SIZE_ERR: The resulting string is too long to fit in a W3CDOMString";
       break;

    case W3CDOMException.HIERARCHY_REQUEST_ERR :         // 3
       msg = "HIERARCHY_REQUEST_ERR: The Node can not be inserted at this location";
       break;

    case W3CDOMException.WRONG_DOCUMENT_ERR :            // 4
       msg = "WRONG_DOCUMENT_ERR: The source and the destination Documents are not the same";
       break;

    case W3CDOMException.INVALID_CHARACTER_ERR :         // 5
       msg = "INVALID_CHARACTER_ERR: The string contains an invalid character";
       break;

    case W3CDOMException.NO_DATA_ALLOWED_ERR :           // 6
       msg = "NO_DATA_ALLOWED_ERR: This Node / NodeList does not support data";
       break;

    case W3CDOMException.NO_MODIFICATION_ALLOWED_ERR :   // 7
       msg = "NO_MODIFICATION_ALLOWED_ERR: This object cannot be modified";
       break;

    case W3CDOMException.NOT_FOUND_ERR :                 // 8
       msg = "NOT_FOUND_ERR: The item cannot be found";
       break;

    case W3CDOMException.NOT_SUPPORTED_ERR :             // 9
       msg = "NOT_SUPPORTED_ERR: This implementation does not support function";
       break;

    case W3CDOMException.INUSE_ATTRIBUTE_ERR :           // 10
       msg = "INUSE_ATTRIBUTE_ERR: The Attribute has already been assigned to another Element";
       break;

// Introduced in W3CDOM Level 2:
    case W3CDOMException.INVALID_STATE_ERR :             // 11
       msg = "INVALID_STATE_ERR: The object is no longer usable";
       break;

    case W3CDOMException.SYNTAX_ERR :                    // 12
       msg = "SYNTAX_ERR: Syntax error";
       break;

    case W3CDOMException.INVALID_MODIFICATION_ERR :      // 13
       msg = "INVALID_MODIFICATION_ERR: Cannot change the type of the object";
       break;

    case W3CDOMException.NAMESPACE_ERR :                 // 14
       msg = "NAMESPACE_ERR: The namespace declaration is incorrect";
       break;

    case W3CDOMException.INVALID_ACCESS_ERR :            // 15
       msg = "INVALID_ACCESS_ERR: The object does not support this function";
       break;

    default :
       msg = "UNKNOWN: Unknown Exception Code ("+ code +")";
  }

  return msg;
}

/**
 * @method W3CDOMImplementation._parseLoop - process SAX events
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  doc : W3CDOMDocument - the Document to contain the parsed XML string
 * @param  p   : XMLP        - the SAX Parser
 *
 * @return : W3CDOMDocument
 */
W3CDOMImplementation.prototype._parseLoop = function W3CDOMImplementation__parseLoop(doc, p) {
  var iEvt, iNode, iAttr, strName;
  iNodeParent = doc;

  var el_close_count = 0;

  var entitiesList = new Array();
  var textNodesList = new Array();

  // if namespaceAware, add default namespace
  if (this.namespaceAware) {
    var iNS = doc.createNamespace(""); // add the default-default namespace
    iNS.setValue("http://www.w3.org/2000/xmlns/");
    doc._namespaces.setNamedItem(iNS);
  }

  // loop until SAX parser stops emitting events
  while(true) {
    // get next event
    iEvt = p.next();

    if (iEvt == XMLP._ELM_B) {                      // Begin-Element Event
      var pName = p.getName();                      // get the Element name
      pName = trim(pName, true, true);              // strip spaces from Element name

      if (!this.namespaceAware) {
        iNode = doc.createElement(p.getName());     // create the Element

        // add attributes to Element
        for(var i = 0; i < p.getAttributeCount(); i++) {
          strName = p.getAttributeName(i);          // get Attribute name
          iAttr = iNode.getAttributeNode(strName);  // if Attribute exists, use it

          if(!iAttr) {
            iAttr = doc.createAttribute(strName);   // otherwise create it
          }

          iAttr.setValue(p.getAttributeValue(i));   // set Attribute value
          iNode.setAttributeNode(iAttr);            // attach Attribute to Element
        }
      }
      else {  // Namespace Aware
        // create element (with empty namespaceURI,
        //  resolve after namespace 'attributes' have been parsed)
        iNode = doc.createElementNS("", p.getName());

        // duplicate ParentNode's Namespace definitions
        iNode._namespaces = iNodeParent._namespaces._cloneNodes(iNode);

        // add attributes to Element
        for(var i = 0; i < p.getAttributeCount(); i++) {
          strName = p.getAttributeName(i);          // get Attribute name

          // if attribute is a namespace declaration
          if (this._isNamespaceDeclaration(strName)) {
            // parse Namespace Declaration
            var namespaceDec = this._parseNSName(strName);

            if (strName != "xmlns") {
              iNS = doc.createNamespace(strName);   // define namespace
            }
            else {
              iNS = doc.createNamespace("");        // redefine default namespace
            }
            iNS.setValue(p.getAttributeValue(i));   // set value = namespaceURI

            iNode._namespaces.setNamedItem(iNS);    // attach namespace to namespace collection
          }
          else {  // otherwise, it is a normal attribute
            iAttr = iNode.getAttributeNode(strName);        // if Attribute exists, use it

            if(!iAttr) {
              iAttr = doc.createAttributeNS("", strName);   // otherwise create it
            }

            iAttr.setValue(p.getAttributeValue(i));         // set Attribute value
            iNode.setAttributeNodeNS(iAttr);                // attach Attribute to Element

            if (this._isIdDeclaration(strName)) {
              iNode.id = p.getAttributeValue(i);    // cache ID for getElementById()
            }
          }
        }

        // resolve namespaceURIs for this Element
        if (iNode._namespaces.getNamedItem(iNode.prefix)) {
          iNode.namespaceURI = iNode._namespaces.getNamedItem(iNode.prefix).value;
        }

        //  for this Element's attributes
        for (var i = 0; i < iNode.attributes.length; i++) {
          if (iNode.attributes.item(i).prefix != "") {  // attributes do not have a default namespace
            if (iNode._namespaces.getNamedItem(iNode.attributes.item(i).prefix)) {
              iNode.attributes.item(i).namespaceURI = iNode._namespaces.getNamedItem(iNode.attributes.item(i).prefix).value;
            }
          }
        }
      }

      // if this is the Root Element
      if (iNodeParent.nodeType == W3CDOMNode.DOCUMENT_NODE) {
        iNodeParent.documentElement = iNode;        // register this Element as the Document.documentElement
      }

      iNodeParent.appendChild(iNode);               // attach Element to parentNode
      iNodeParent = iNode;                          // descend one level of the W3CDOM Tree
    }

    else if(iEvt == XMLP._ELM_E) {                  // End-Element Event
      iNodeParent = iNodeParent.parentNode;         // ascend one level of the W3CDOM Tree
    }

    else if(iEvt == XMLP._ELM_EMP) {                // Empty Element Event
      pName = p.getName();                          // get the Element name
      pName = trim(pName, true, true);              // strip spaces from Element name

      if (!this.namespaceAware) {
        iNode = doc.createElement(pName);           // create the Element

        // add attributes to Element
        for(var i = 0; i < p.getAttributeCount(); i++) {
          strName = p.getAttributeName(i);          // get Attribute name
          iAttr = iNode.getAttributeNode(strName);  // if Attribute exists, use it

          if(!iAttr) {
            iAttr = doc.createAttribute(strName);   // otherwise create it
          }

          iAttr.setValue(p.getAttributeValue(i));   // set Attribute value
          iNode.setAttributeNode(iAttr);            // attach Attribute to Element
        }
      }
      else {  // Namespace Aware
        // create element (with empty namespaceURI,
        //  resolve after namespace 'attributes' have been parsed)
        iNode = doc.createElementNS("", p.getName());

        // duplicate ParentNode's Namespace definitions
        iNode._namespaces = iNodeParent._namespaces._cloneNodes(iNode);

        // add attributes to Element
        for(var i = 0; i < p.getAttributeCount(); i++) {
          strName = p.getAttributeName(i);          // get Attribute name

          // if attribute is a namespace declaration
          if (this._isNamespaceDeclaration(strName)) {
            // parse Namespace Declaration
            var namespaceDec = this._parseNSName(strName);

            if (strName != "xmlns") {
              iNS = doc.createNamespace(strName);   // define namespace
            }
            else {
              iNS = doc.createNamespace("");        // redefine default namespace
            }
            iNS.setValue(p.getAttributeValue(i));   // set value = namespaceURI

            iNode._namespaces.setNamedItem(iNS);    // attach namespace to namespace collection
          }
          else {  // otherwise, it is a normal attribute
            iAttr = iNode.getAttributeNode(strName);        // if Attribute exists, use it

            if(!iAttr) {
              iAttr = doc.createAttributeNS("", strName);   // otherwise create it
            }

            iAttr.setValue(p.getAttributeValue(i));         // set Attribute value
            iNode.setAttributeNodeNS(iAttr);                // attach Attribute to Element

            if (this._isIdDeclaration(strName)) {
              iNode.id = p.getAttributeValue(i);    // cache ID for getElementById()
            }
          }
        }

        // resolve namespaceURIs for this Element
        if (iNode._namespaces.getNamedItem(iNode.prefix)) {
          iNode.namespaceURI = iNode._namespaces.getNamedItem(iNode.prefix).value;
        }

        //  for this Element's attributes
        for (var i = 0; i < iNode.attributes.length; i++) {
          if (iNode.attributes.item(i).prefix != "") {  // attributes do not have a default namespace
            if (iNode._namespaces.getNamedItem(iNode.attributes.item(i).prefix)) {
              iNode.attributes.item(i).namespaceURI = iNode._namespaces.getNamedItem(iNode.attributes.item(i).prefix).value;
            }
          }
        }
      }

      // if this is the Root Element
      if (iNodeParent.nodeType == W3CDOMNode.DOCUMENT_NODE) {
        iNodeParent.documentElement = iNode;        // register this Element as the Document.documentElement
      }

      iNodeParent.appendChild(iNode);               // attach Element to parentNode
    }
    else if(iEvt == XMLP._TEXT || iEvt == XMLP._ENTITY) {                   // TextNode and entity Events
      // get Text content
      var pContent = p.getContent().substring(p.getContentBegin(), p.getContentEnd());
      
	  if (!this.preserveWhiteSpace ) {
		if (trim(pContent, true, true) == "") {
			pContent = ""; //this will cause us not to create the text node below
		}
	  }
	  
      if (pContent.length > 0) {                    // ignore empty TextNodes
        var textNode = doc.createTextNode(pContent);
        iNodeParent.appendChild(textNode); // attach TextNode to parentNode

        //the sax parser breaks up text nodes when it finds an entity. For
        //example hello&lt;there will fire a text, an entity and another text
        //this sucks for the dom parser because it looks to us in this logic
        //as three text nodes. I fix this by keeping track of the entity nodes
        //and when we're done parsing, calling normalize on their parent to
        //turn the multiple text nodes into one, which is what W3CDOM users expect
        //the code to do this is at the bottom of this function
        if (iEvt == XMLP._ENTITY) {
            entitiesList[entitiesList.length] = textNode;
        }
		else {
			//I can't properly decide how to handle preserve whitespace
			//until the siblings of the text node are built due to 
			//the entitiy handling described above. I don't know that this
			//will be all of the text node or not, so trimming is not appropriate
			//at this time. Keep a list of all the text nodes for now
			//and we'll process the preserve whitespace stuff at a later time.
			textNodesList[textNodesList.length] = textNode;
		}
      }
    }
    else if(iEvt == XMLP._PI) {                     // ProcessingInstruction Event
      // attach ProcessingInstruction to parentNode
      iNodeParent.appendChild(doc.createProcessingInstruction(p.getName(), p.getContent().substring(p.getContentBegin(), p.getContentEnd())));
    }
    else if(iEvt == XMLP._CDATA) {                  // CDATA Event
      // get CDATA data
      pContent = p.getContent().substring(p.getContentBegin(), p.getContentEnd());

      if (!this.preserveWhiteSpace) {
        pContent = trim(pContent, true, true);      // trim whitespace
        pContent.replace(/ +/g, ' ');               // collapse multiple spaces to 1 space
      }

      if (pContent.length > 0) {                    // ignore empty CDATANodes
        iNodeParent.appendChild(doc.createCDATASection(pContent)); // attach CDATA to parentNode
      }
    }
    else if(iEvt == XMLP._COMMENT) {                // Comment Event
      // get COMMENT data
      var pContent = p.getContent().substring(p.getContentBegin(), p.getContentEnd());

      if (!this.preserveWhiteSpace) {
        pContent = trim(pContent, true, true);      // trim whitespace
        pContent.replace(/ +/g, ' ');               // collapse multiple spaces to 1 space
      }

      if (pContent.length > 0) {                    // ignore empty CommentNodes
        iNodeParent.appendChild(doc.createComment(pContent));  // attach Comment to parentNode
      }
    }
    else if(iEvt == XMLP._DTD) {                    // ignore DTD events
    }
    else if(iEvt == XMLP._ERROR) {
      throw(new W3CDOMException(W3CDOMException.SYNTAX_ERR));
      // alert("Fatal Error: " + p.getContent() + "\nLine: " + p.getLineNumber() + "\nColumn: " + p.getColumnNumber() + "\n");
      // break;
    }
    else if(iEvt == XMLP._NONE) {                   // no more events
      if (iNodeParent == doc) {                     // confirm that we have recursed back up to root
        break;
      }
      else {
        throw(new W3CDOMException(W3CDOMException.SYNTAX_ERR));  // one or more Tags were not closed properly
      }
    }
  }

  //normalize any entities in the W3CDOM to a single textNode
  var intCount = entitiesList.length;
  for (intLoop = 0; intLoop < intCount; intLoop++) {
      var entity = entitiesList[intLoop];
      //its possible (if for example two entities were in the
      //same domnode, that the normalize on the first entitiy
      //will remove the parent for the second. Only do normalize
      //if I can find a parent node
      var parentNode = entity.getParentNode();
      if (parentNode) {
          parentNode.normalize();
		  
		  //now do whitespace (if necessary)
		  //it was not done for text nodes that have entities
		  if(!this.preserveWhiteSpace) {
		  		var children = parentNode.getChildNodes();
				var intCount2 = children.getLength();
				for ( intLoop2 = 0; intLoop2 < intCount2; intLoop2++) {
					var child = children.item(intLoop2);
					if (child.getNodeType() == W3CDOMNode.TEXT_NODE) {
						var childData = child.getData();
						childData = trim(childData, true, true);
						childData.replace(/ +/g, ' ');
						child.setData(childData);
					}
				}
		  }
      }
  }
  
  //do the preserve whitespace processing on the rest of the text nodes
  //It's possible (due to the processing above) that the node will have been
  //removed from the tree. Only do whitespace checking if parentNode is not null.
  //This may duplicate the whitespace processing for some nodes that had entities in them
  //but there's no way around that
  if (!this.preserveWhiteSpace) {
  	var intCount = textNodesList.length;
	for (intLoop = 0; intLoop < intCount; intLoop++) {
		var node = textNodesList[intLoop];
		if (node.getParentNode() != null) {
			var nodeData = node.getData();
			nodeData = trim(nodeData, true, true);
			nodeData.replace(/ +/g, ' ');
			node.setData(nodeData);
		}
	}
  
  }
};

/**
 * @method W3CDOMImplementation._isNamespaceDeclaration - Return true, if attributeName is a namespace declaration
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  attributeName : string - the attribute name
 *
 * @return : boolean
 */
W3CDOMImplementation.prototype._isNamespaceDeclaration = function W3CDOMImplementation__isNamespaceDeclaration(attributeName) {
  // test if attributeName is 'xmlns'
  return (attributeName.indexOf('xmlns') > -1);
}

/**
 * @method W3CDOMImplementation._isIdDeclaration - Return true, if attributeName is an id declaration
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  attributeName : string - the attribute name
 *
 * @return : boolean
 */
W3CDOMImplementation.prototype._isIdDeclaration = function W3CDOMImplementation__isIdDeclaration(attributeName) {
  // test if attributeName is 'id' (case insensitive)
  return (attributeName.toLowerCase() == 'id');
}

/**
 * @method W3CDOMImplementation._isValidName - Return true,
 *   if name contains no invalid characters
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - the candidate name
 *
 * @return : boolean
 */
W3CDOMImplementation.prototype._isValidName = function W3CDOMImplementation__isValidName(name) {
  // test if name contains only valid characters
  return name.match(re_validName);
}
re_validName = /^[a-zA-Z_:][a-zA-Z0-9\.\-_:]*$/;

/**
 * @method W3CDOMImplementation._isValidString - Return true, if string does not contain any illegal chars
 *  All of the characters 0 through 31 and character 127 are nonprinting control characters.
 *  With the exception of characters 09, 10, and 13, (Ox09, Ox0A, and Ox0D)
 *  Note: different from _isValidName in that ValidStrings may contain spaces
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - the candidate string
 *
 * @return : boolean
 */
W3CDOMImplementation.prototype._isValidString = function W3CDOMImplementation__isValidString(name) {
  // test that string does not contains invalid characters
  return (name.search(re_invalidStringChars) < 0);
}
re_invalidStringChars = /\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x0B|\x0C|\x0E|\x0F|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1A|\x1B|\x1C|\x1D|\x1E|\x1F|\x7F/

/**
 * @method W3CDOMImplementation._parseNSName - parse the namespace name.
 *  if there is no colon, the
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  qualifiedName : string - The qualified name
 *
 * @return : NSName - [
 *                     .prefix        : string - The prefix part of the qname
 *                     .namespaceName : string - The namespaceURI part of the qname
 *                    ]
 */
W3CDOMImplementation.prototype._parseNSName = function W3CDOMImplementation__parseNSName(qualifiedName) {
  var resultNSName = new Object();

  resultNSName.prefix          = qualifiedName;  // unless the qname has a namespaceName, the prefix is the entire String
  resultNSName.namespaceName   = "";

  // split on ':'
  delimPos = qualifiedName.indexOf(':');

  if (delimPos > -1) {
    // get prefix
    resultNSName.prefix        = qualifiedName.substring(0, delimPos);

    // get namespaceName
    resultNSName.namespaceName = qualifiedName.substring(delimPos +1, qualifiedName.length);
  }

  return resultNSName;
}

/**
 * @method W3CDOMImplementation._parseQName - parse the qualified name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  qualifiedName : string - The qualified name
 *
 * @return : QName
 */
W3CDOMImplementation.prototype._parseQName = function W3CDOMImplementation__parseQName(qualifiedName) {
  var resultQName = new Object();

  resultQName.localName = qualifiedName;  // unless the qname has a prefix, the local name is the entire String
  resultQName.prefix    = "";

  // split on ':'
  delimPos = qualifiedName.indexOf(':');

  if (delimPos > -1) {
    // get prefix
    resultQName.prefix    = qualifiedName.substring(0, delimPos);

    // get localName
    resultQName.localName = qualifiedName.substring(delimPos +1, qualifiedName.length);
  }

  return resultQName;
}

/**
 * @class  W3CDOMNodeList - provides the abstraction of an ordered collection of nodes
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - the ownerDocument
 * @param  parentNode    : W3CDOMNode - the node that the W3CDOMNodeList is attached to (or null)
 */
W3CDOMNodeList = function(ownerDocument, parentNode) {
  this._class = addClass(this._class, "W3CDOMNodeList");
  this._nodes = new Array();

  this.length = 0;
  this.parentNode = parentNode;
  this.ownerDocument = ownerDocument;

  this._readonly = false;
};

/**
 * @method W3CDOMNodeList.getLength - Java style gettor for .length
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : int
 */
W3CDOMNodeList.prototype.getLength = function W3CDOMNodeList_getLength() {
  return this.length;
};

/**
 * @method W3CDOMNodeList.item - Returns the indexth item in the collection.
 *   If index is greater than or equal to the number of nodes in the list, this returns null.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  index : int - Index into the collection.
 *
 * @return : W3CDOMNode - The node at the indexth position in the NodeList, or null if that is not a valid index
 */
W3CDOMNodeList.prototype.item = function W3CDOMNodeList_item(index) {
  var ret = null;

  if ((index >= 0) && (index < this._nodes.length)) { // bounds check
    ret = this._nodes[index];                    // return selected Node
  }

  return ret;                                    // if the index is out of bounds, default value null is returned
};

/**
 * @method W3CDOMNodeList._findItemIndex - find the item index of the node with the specified internal id
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  id : int - unique internal id
 *
 * @return : int
 */
W3CDOMNodeList.prototype._findItemIndex = function W3CDOMNodeList__findItemIndex(id) {
  var ret = -1;

  // test that id is valid
  if (id > -1) {
    for (var i=0; i<this._nodes.length; i++) {
      // compare id to each node's _id
      if (this._nodes[i]._id == id) {            // found it!
        ret = i;
        break;
      }
    }
  }

  return ret;                                    // if node is not found, default value -1 is returned
};

/**
 * @method W3CDOMNodeList._insertBefore - insert the specified Node into the NodeList before the specified index
 *   Used by W3CDOMNode.insertBefore(). Note: W3CDOMNode.insertBefore() is responsible for Node Pointer surgery
 *   W3CDOMNodeList._insertBefore() simply modifies the internal data structure (Array).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild      : W3CDOMNode - the Node to be inserted
 * @param  refChildIndex : int     - the array index to insert the Node before
 */
W3CDOMNodeList.prototype._insertBefore = function W3CDOMNodeList__insertBefore(newChild, refChildIndex) {
  if ((refChildIndex >= 0) && (refChildIndex < this._nodes.length)) { // bounds check
    // get array containing children prior to refChild
    var tmpArr = new Array();
    tmpArr = this._nodes.slice(0, refChildIndex);

    if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {  // node is a DocumentFragment
      // append the children of DocumentFragment
      tmpArr = tmpArr.concat(newChild.childNodes._nodes);
    }
    else {
      // append the newChild
      tmpArr[tmpArr.length] = newChild;
    }

    // append the remaining original children (including refChild)
    this._nodes = tmpArr.concat(this._nodes.slice(refChildIndex));

    this.length = this._nodes.length;            // update length
  }
};

/**
 * @method W3CDOMNodeList._replaceChild - replace the specified Node in the NodeList at the specified index
 *   Used by W3CDOMNode.replaceChild(). Note: W3CDOMNode.replaceChild() is responsible for Node Pointer surgery
 *   W3CDOMNodeList._replaceChild() simply modifies the internal data structure (Array).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild      : W3CDOMNode - the Node to be inserted
 * @param  refChildIndex : int     - the array index to hold the Node
 */
W3CDOMNodeList.prototype._replaceChild = function W3CDOMNodeList__replaceChild(newChild, refChildIndex) {
  var ret = null;

  if ((refChildIndex >= 0) && (refChildIndex < this._nodes.length)) { // bounds check
    ret = this._nodes[refChildIndex];            // preserve old child for return

    if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {  // node is a DocumentFragment
      // get array containing children prior to refChild
      var tmpArr = new Array();
      tmpArr = this._nodes.slice(0, refChildIndex);

      // append the children of DocumentFragment
      tmpArr = tmpArr.concat(newChild.childNodes._nodes);

      // append the remaining original children (not including refChild)
      this._nodes = tmpArr.concat(this._nodes.slice(refChildIndex + 1));
    }
    else {
      // simply replace node in array (links between Nodes are made at higher level)
      this._nodes[refChildIndex] = newChild;
    }
  }

  return ret;                                   // return replaced node
};

/**
 * @method W3CDOMNodeList._removeChild - remove the specified Node in the NodeList at the specified index
 *   Used by W3CDOMNode.removeChild(). Note: W3CDOMNode.removeChild() is responsible for Node Pointer surgery
 *   W3CDOMNodeList._replaceChild() simply modifies the internal data structure (Array).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  refChildIndex : int - the array index holding the Node to be removed
 */
W3CDOMNodeList.prototype._removeChild = function W3CDOMNodeList__removeChild(refChildIndex) {
  var ret = null;

  if (refChildIndex > -1) {                              // found it!
    ret = this._nodes[refChildIndex];                    // return removed node

    // rebuild array without removed child
    var tmpArr = new Array();
    tmpArr = this._nodes.slice(0, refChildIndex);
    this._nodes = tmpArr.concat(this._nodes.slice(refChildIndex +1));

    this.length = this._nodes.length;            // update length
  }

  return ret;                                   // return removed node
};

/**
 * @method W3CDOMNodeList._appendChild - append the specified Node to the NodeList
 *   Used by W3CDOMNode.appendChild(). Note: W3CDOMNode.appendChild() is responsible for Node Pointer surgery
 *   W3CDOMNodeList._appendChild() simply modifies the internal data structure (Array).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild      : W3CDOMNode - the Node to be inserted
 */
W3CDOMNodeList.prototype._appendChild = function W3CDOMNodeList__appendChild(newChild) {

  if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {  // node is a DocumentFragment
    // append the children of DocumentFragment
    this._nodes = this._nodes.concat(newChild.childNodes._nodes);
  }
  else {
    // simply add node to array (links between Nodes are made at higher level)
    this._nodes[this._nodes.length] = newChild;
  }

  this.length = this._nodes.length;              // update length
};

/**
 * @method W3CDOMNodeList._cloneNodes - Returns a NodeList containing clones of the Nodes in this NodeList
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  deep : boolean - If true, recursively clone the subtree under each of the nodes;
 *   if false, clone only the nodes themselves (and their attributes, if it is an Element).
 * @param  parentNode : W3CDOMNode - the new parent of the cloned NodeList
 *
 * @return : W3CDOMNodeList - NodeList containing clones of the Nodes in this NodeList
 */
W3CDOMNodeList.prototype._cloneNodes = function W3CDOMNodeList__cloneNodes(deep, parentNode) {
  var cloneNodeList = new W3CDOMNodeList(this.ownerDocument, parentNode);

  // create list containing clones of each child
  for (var i=0; i < this._nodes.length; i++) {
    cloneNodeList._appendChild(this._nodes[i].cloneNode(deep));
  }

  return cloneNodeList;
};

/**
 * @method W3CDOMNodeList.toString - Serialize this NodeList into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMNodeList.prototype.toString = function W3CDOMNodeList_toString() {
  var ret = "";

  // create string containing the concatenation of the string values of each child
  for (var i=0; i < this.length; i++) {
    ret += this._nodes[i].toString();
  }

  return ret;
};

/**
 * @class  W3CDOMNamedNodeMap - used to represent collections of nodes that can be accessed by name
 *  typically a set of Element attributes
 *
 * @extends W3CDOMNodeList - note W3C spec says that this is not the case,
 *   but we need an item() method identicle to W3CDOMNodeList's, so why not?
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - the ownerDocument
 * @param  parentNode    : W3CDOMNode - the node that the W3CDOMNamedNodeMap is attached to (or null)
 */
W3CDOMNamedNodeMap = function(ownerDocument, parentNode) {
  this._class = addClass(this._class, "W3CDOMNamedNodeMap");
  this.W3CDOMNodeList = W3CDOMNodeList;
  this.W3CDOMNodeList(ownerDocument, parentNode);
};
W3CDOMNamedNodeMap.prototype = new W3CDOMNodeList;

/**
 * @method W3CDOMNamedNodeMap.getNamedItem - Retrieves a node specified by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - Name of a node to retrieve
 *
 * @return : W3CDOMNode
 */
W3CDOMNamedNodeMap.prototype.getNamedItem = function W3CDOMNamedNodeMap_getNamedItem(name) {
  var ret = null;

  // test that Named Node exists
  var itemIndex = this._findNamedItemIndex(name);

  if (itemIndex > -1) {                          // found it!
    ret = this._nodes[itemIndex];                // return NamedNode
  }

  return ret;                                    // if node is not found, default value null is returned
};

/**
 * @method W3CDOMNamedNodeMap.setNamedItem - Adds a node using its nodeName attribute
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  arg : W3CDOMNode - A node to store in a named node map.
 *   The node will later be accessible using the value of the nodeName attribute of the node.
 *   If a node with that name is already present in the map, it is replaced by the new one.
 *
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this NamedNodeMap is readonly.
 * @throws : W3CDOMException - INUSE_ATTRIBUTE_ERR: Raised if arg is an Attr that is already an attribute of another Element object.
 *  The W3CDOM user must explicitly clone Attr nodes to re-use them in other elements.
 *
 * @return : W3CDOMNode - If the new Node replaces an existing node with the same name the previously existing Node is returned,
 *   otherwise null is returned
 */
W3CDOMNamedNodeMap.prototype.setNamedItem = function W3CDOMNamedNodeMap_setNamedItem(arg) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if arg was not created by this Document
    if (this.ownerDocument != arg.ownerDocument) {
      throw(new W3CDOMException(W3CDOMException.WRONG_DOCUMENT_ERR));
    }

    // throw Exception if W3CDOMNamedNodeMap is readonly
    if (this._readonly || (this.parentNode && this.parentNode._readonly)) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if arg is already an attribute of another Element object
    if (arg.ownerElement && (arg.ownerElement != this.parentNode)) {
      throw(new W3CDOMException(W3CDOMException.INUSE_ATTRIBUTE_ERR));
    }
  }

  // get item index
  var itemIndex = this._findNamedItemIndex(arg.name);
  var ret = null;

  if (itemIndex > -1) {                          // found it!
    ret = this._nodes[itemIndex];                // use existing Attribute

    // throw Exception if W3CDOMAttr is readonly
    if (this.ownerDocument.implementation.errorChecking && ret._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }
    else {
      this._nodes[itemIndex] = arg;                // over-write existing NamedNode
    }
  }
  else {
    this._nodes[this.length] = arg;              // add new NamedNode
  }

  this.length = this._nodes.length;              // update length

  arg.ownerElement = this.parentNode;            // update ownerElement

  return ret;                                    // return old node or null
};

/**
 * @method W3CDOMNamedNodeMap.removeNamedItem - Removes a node specified by name.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - The name of a node to remove
 *
 * @throws : W3CDOMException - NOT_FOUND_ERR: Raised if there is no node named name in this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this NamedNodeMap is readonly.
 *
 * @return : W3CDOMNode - The node removed from the map or null if no node with such a name exists.
 */
W3CDOMNamedNodeMap.prototype.removeNamedItem = function W3CDOMNamedNodeMap_removeNamedItem(name) {
  var ret = null;
  // test for exceptions
  // throw Exception if W3CDOMNamedNodeMap is readonly
  if (this.ownerDocument.implementation.errorChecking && (this._readonly || (this.parentNode && this.parentNode._readonly))) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // get item index
  var itemIndex = this._findNamedItemIndex(name);

  // throw Exception if there is no node named name in this map
  if (this.ownerDocument.implementation.errorChecking && (itemIndex < 0)) {
    throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
  }

  // get Node
  var oldNode = this._nodes[itemIndex];

  // throw Exception if Node is readonly
  if (this.ownerDocument.implementation.errorChecking && oldNode._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // return removed node
  return this._removeChild(itemIndex);
};

/**
 * @method W3CDOMNamedNodeMap.getNamedItemNS - Retrieves a node specified by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : W3CDOMNode
 */
W3CDOMNamedNodeMap.prototype.getNamedItemNS = function W3CDOMNamedNodeMap_getNamedItemNS(namespaceURI, localName) {
  var ret = null;

  // test that Named Node exists
  var itemIndex = this._findNamedItemNSIndex(namespaceURI, localName);

  if (itemIndex > -1) {                          // found it!
    ret = this._nodes[itemIndex];                // return NamedNode
  }

  return ret;                                    // if node is not found, default value null is returned
};

/**
 * @method W3CDOMNamedNodeMap.setNamedItemNS - Adds a node using
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  arg : string - A node to store in a named node map.
 *   The node will later be accessible using the value of the nodeName attribute of the node.
 *   If a node with that name is already present in the map, it is replaced by the new one.
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this NamedNodeMap is readonly.
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - INUSE_ATTRIBUTE_ERR: Raised if arg is an Attr that is already an attribute of another Element object.
 *   The W3CDOM user must explicitly clone Attr nodes to re-use them in other elements.
 *
 * @return : W3CDOMNode - If the new Node replaces an existing node with the same name the previously existing Node is returned,
 *   otherwise null is returned
 */
W3CDOMNamedNodeMap.prototype.setNamedItemNS = function W3CDOMNamedNodeMap_setNamedItemNS(arg) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if W3CDOMNamedNodeMap is readonly
    if (this._readonly || (this.parentNode && this.parentNode._readonly)) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if arg was not created by this Document
    if (this.ownerDocument != arg.ownerDocument) {
      throw(new W3CDOMException(W3CDOMException.WRONG_DOCUMENT_ERR));
    }

    // throw Exception if arg is already an attribute of another Element object
    if (arg.ownerElement && (arg.ownerElement != this.parentNode)) {
      throw(new W3CDOMException(W3CDOMException.INUSE_ATTRIBUTE_ERR));
    }
  }

  // get item index
  var itemIndex = this._findNamedItemNSIndex(arg.namespaceURI, arg.localName);
  var ret = null;

  if (itemIndex > -1) {                          // found it!
    ret = this._nodes[itemIndex];                // use existing Attribute
    // throw Exception if W3CDOMAttr is readonly
    if (this.ownerDocument.implementation.errorChecking && ret._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }
    else {
      this._nodes[itemIndex] = arg;                // over-write existing NamedNode
    }
  }
  else {
    this._nodes[this.length] = arg;              // add new NamedNode
  }

  this.length = this._nodes.length;              // update length

  arg.ownerElement = this.parentNode;


  return ret;                                    // return old node or null
};

/**
 * @method W3CDOMNamedNodeMap.removeNamedItemNS - Removes a node specified by name.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @throws : W3CDOMException - NOT_FOUND_ERR: Raised if there is no node with the specified namespaceURI and localName in this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this NamedNodeMap is readonly.
 *
 * @return : W3CDOMNode - The node removed from the map or null if no node with such a name exists.
 */
W3CDOMNamedNodeMap.prototype.removeNamedItemNS = function W3CDOMNamedNodeMap_removeNamedItemNS(namespaceURI, localName) {
  var ret = null;

  // test for exceptions
  // throw Exception if W3CDOMNamedNodeMap is readonly
  if (this.ownerDocument.implementation.errorChecking && (this._readonly || (this.parentNode && this.parentNode._readonly))) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // get item index
  var itemIndex = this._findNamedItemNSIndex(namespaceURI, localName);

  // throw Exception if there is no matching node in this map
  if (this.ownerDocument.implementation.errorChecking && (itemIndex < 0)) {
    throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
  }

  // get Node
  var oldNode = this._nodes[itemIndex];

  // throw Exception if Node is readonly
  if (this.ownerDocument.implementation.errorChecking && oldNode._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  return this._removeChild(itemIndex);             // return removed node
};

/**
 * @method W3CDOMNamedNodeMap._findNamedItemIndex - find the item index of the node with the specified name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - the name of the required node
 *
 * @return : int
 */
W3CDOMNamedNodeMap.prototype._findNamedItemIndex = function W3CDOMNamedNodeMap__findNamedItemIndex(name) {
  var ret = -1;

  // loop through all nodes
  for (var i=0; i<this._nodes.length; i++) {
    // compare name to each node's nodeName
    if (this._nodes[i].name == name) {         // found it!
      ret = i;
      break;
    }
  }

  return ret;                                    // if node is not found, default value -1 is returned
};

/**
 * @method W3CDOMNamedNodeMap._findNamedItemNSIndex - find the item index of the node with the specified namespaceURI and localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : int
 */
W3CDOMNamedNodeMap.prototype._findNamedItemNSIndex = function W3CDOMNamedNodeMap__findNamedItemNSIndex(namespaceURI, localName) {
  var ret = -1;

  // test that localName is not null
  if (localName) {
    // loop through all nodes
    for (var i=0; i<this._nodes.length; i++) {
      // compare name to each node's namespaceURI and localName
      if ((this._nodes[i].namespaceURI == namespaceURI) && (this._nodes[i].localName == localName)) {
        ret = i;                                 // found it!
        break;
      }
    }
  }

  return ret;                                    // if node is not found, default value -1 is returned
};

/**
 * @method W3CDOMNamedNodeMap._hasAttribute - Returns true if specified node exists
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - the name of the required node
 *
 * @return : boolean
 */
W3CDOMNamedNodeMap.prototype._hasAttribute = function W3CDOMNamedNodeMap__hasAttribute(name) {
  var ret = false;

  // test that Named Node exists
  var itemIndex = this._findNamedItemIndex(name);

  if (itemIndex > -1) {                          // found it!
    ret = true;                                  // return true
  }

  return ret;                                    // if node is not found, default value false is returned
}

/**
 * @method W3CDOMNamedNodeMap._hasAttributeNS - Returns true if specified node exists
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : boolean
 */
W3CDOMNamedNodeMap.prototype._hasAttributeNS = function W3CDOMNamedNodeMap__hasAttributeNS(namespaceURI, localName) {
  var ret = false;

  // test that Named Node exists
  var itemIndex = this._findNamedItemNSIndex(namespaceURI, localName);

  if (itemIndex > -1) {                          // found it!
    ret = true;                                  // return true
  }

  return ret;                                    // if node is not found, default value false is returned
}

/**
 * @method W3CDOMNamedNodeMap._cloneNodes - Returns a NamedNodeMap containing clones of the Nodes in this NamedNodeMap
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  parentNode : W3CDOMNode - the new parent of the cloned NodeList
 *
 * @return : W3CDOMNamedNodeMap - NamedNodeMap containing clones of the Nodes in this W3CDOMNamedNodeMap
 */
W3CDOMNamedNodeMap.prototype._cloneNodes = function W3CDOMNamedNodeMap__cloneNodes(parentNode) {
  var cloneNamedNodeMap = new W3CDOMNamedNodeMap(this.ownerDocument, parentNode);

  // create list containing clones of all children
  for (var i=0; i < this._nodes.length; i++) {
    cloneNamedNodeMap._appendChild(this._nodes[i].cloneNode(false));
  }

  return cloneNamedNodeMap;
};

/**
 * @method W3CDOMNamedNodeMap.toString - Serialize this NodeMap into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMNamedNodeMap.prototype.toString = function W3CDOMNamedNodeMap_toString() {
  var ret = "";

  // create string containing concatenation of all (but last) Attribute string values (separated by spaces)
  for (var i=0; i < this.length -1; i++) {
    ret += this._nodes[i].toString() +" ";
  }

  // add last Attribute to string (without trailing space)
  if (this.length > 0) {
    ret += this._nodes[this.length -1].toString();
  }

  return ret;
};

/**
 * @class  W3CDOMNamespaceNodeMap - used to represent collections of namespace nodes that can be accessed by name
 *  typically a set of Element attributes
 *
 * @extends W3CDOMNamedNodeMap
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - the ownerDocument
 * @param  parentNode    : W3CDOMNode - the node that the W3CDOMNamespaceNodeMap is attached to (or null)
 */
W3CDOMNamespaceNodeMap = function(ownerDocument, parentNode) {
  this._class = addClass(this._class, "W3CDOMNamespaceNodeMap");
  this.W3CDOMNamedNodeMap = W3CDOMNamedNodeMap;
  this.W3CDOMNamedNodeMap(ownerDocument, parentNode);
};
W3CDOMNamespaceNodeMap.prototype = new W3CDOMNamedNodeMap;

/**
 * @method W3CDOMNamespaceNodeMap._findNamedItemIndex - find the item index of the node with the specified localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  localName : string - the localName of the required node
 *
 * @return : int
 */
W3CDOMNamespaceNodeMap.prototype._findNamedItemIndex = function W3CDOMNamespaceNodeMap__findNamedItemIndex(localName) {
  var ret = -1;

  // loop through all nodes
  for (var i=0; i<this._nodes.length; i++) {
    // compare name to each node's nodeName
    if (this._nodes[i].localName == localName) {         // found it!
      ret = i;
      break;
    }
  }

  return ret;                                    // if node is not found, default value -1 is returned
};


/**
 * @method W3CDOMNamespaceNodeMap._cloneNodes - Returns a NamespaceNodeMap containing clones of the Nodes in this NamespaceNodeMap
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  parentNode : W3CDOMNode - the new parent of the cloned NodeList
 *
 * @return : W3CDOMNamespaceNodeMap - NamespaceNodeMap containing clones of the Nodes in this NamespaceNodeMap
 */
W3CDOMNamespaceNodeMap.prototype._cloneNodes = function W3CDOMNamespaceNodeMap__cloneNodes(parentNode) {
  var cloneNamespaceNodeMap = new W3CDOMNamespaceNodeMap(this.ownerDocument, parentNode);

  // create list containing clones of all children
  for (var i=0; i < this._nodes.length; i++) {
    cloneNamespaceNodeMap._appendChild(this._nodes[i].cloneNode(false));
  }

  return cloneNamespaceNodeMap;
};

/**
 * @method W3CDOMNamespaceNodeMap.toString - Serialize this NamespaceNodeMap into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMNamespaceNodeMap.prototype.toString = function W3CDOMNamespaceNodeMap_toString() {
  var ret = "";

  // identify namespaces declared local to this Element (ie, not inherited)
  for (var ind = 0; ind < this._nodes.length; ind++) {
    // if namespace declaration does not exist in the containing node's, parentNode's namespaces
    var ns = null;
    try {
        var ns = this.parentNode.parentNode._namespaces.getNamedItem(this._nodes[ind].localName);
    }
    catch (e) {
        //breaking to prevent default namespace being inserted into return value
        break;
    }
    if (!(ns && (""+ ns.nodeValue == ""+ this._nodes[ind].nodeValue))) {
      // display the namespace declaration
      ret += this._nodes[ind].toString() +" ";
    }
  }

  return ret;
};

/**
 * @class  W3CDOMNode - The Node interface is the primary datatype for the entire Document Object Model.
 *   It represents a single node in the document tree.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMNode = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMNode");

  if (ownerDocument) {
    this._id = ownerDocument._genId();           // generate unique internal id
  }

  this.namespaceURI = "";                        // The namespace URI of this node (Level 2)
  this.prefix       = "";                        // The namespace prefix of this node (Level 2)
  this.localName    = "";                        // The localName of this node (Level 2)

  this.nodeName = "";                            // The name of this node
  this.nodeValue = "";                           // The value of this node
  this.nodeType = 0;                             // A code representing the type of the underlying object

  // The parent of this node. All nodes, except Document, DocumentFragment, and Attr may have a parent.
  // However, if a node has just been created and not yet added to the tree, or if it has been removed from the tree, this is null
  this.parentNode      = null;

  // A NodeList that contains all children of this node. If there are no children, this is a NodeList containing no nodes.
  // The content of the returned NodeList is "live" in the sense that, for instance, changes to the children of the node object
  // that it was created from are immediately reflected in the nodes returned by the NodeList accessors;
  // it is not a static snapshot of the content of the node. This is true for every NodeList, including the ones returned by the getElementsByTagName method.
  this.childNodes      = new W3CDOMNodeList(ownerDocument, this);

  this.firstChild      = null;                   // The first child of this node. If there is no such node, this is null
  this.lastChild       = null;                   // The last child of this node. If there is no such node, this is null.
  this.previousSibling = null;                   // The node immediately preceding this node. If there is no such node, this is null.
  this.nextSibling     = null;                   // The node immediately following this node. If there is no such node, this is null.

  this.attributes = new W3CDOMNamedNodeMap(ownerDocument, this);   // A NamedNodeMap containing the attributes of this node (if it is an Element) or null otherwise.
  this.ownerDocument   = ownerDocument;          // The Document object associated with this node
  this._namespaces = new W3CDOMNamespaceNodeMap(ownerDocument, this);  // The namespaces in scope for this node

  this._readonly = false;
};

// nodeType constants
W3CDOMNode.ELEMENT_NODE                = 1;
W3CDOMNode.ATTRIBUTE_NODE              = 2;
W3CDOMNode.TEXT_NODE                   = 3;
W3CDOMNode.CDATA_SECTION_NODE          = 4;
W3CDOMNode.ENTITY_REFERENCE_NODE       = 5;
W3CDOMNode.ENTITY_NODE                 = 6;
W3CDOMNode.PROCESSING_INSTRUCTION_NODE = 7;
W3CDOMNode.COMMENT_NODE                = 8;
W3CDOMNode.DOCUMENT_NODE               = 9;
W3CDOMNode.DOCUMENT_TYPE_NODE          = 10;
W3CDOMNode.DOCUMENT_FRAGMENT_NODE      = 11;
W3CDOMNode.NOTATION_NODE               = 12;
W3CDOMNode.NAMESPACE_NODE              = 13;

/**
 * @method W3CDOMNode.hasAttributes
 *
 * @author Jon van Noort (jon@webarcana.com.au) & David Joham (djoham@yahoo.com)
 *
 * @return : boolean
 */
W3CDOMNode.prototype.hasAttributes = function W3CDOMNode_hasAttributes() {
    if (this.attributes.length == 0) {
        return false;
    }
    else {
        return true;
    }
};

/**
 * @method W3CDOMNode.getNodeName - Java style gettor for .nodeName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMNode.prototype.getNodeName = function W3CDOMNode_getNodeName() {
  return this.nodeName;
};

/**
 * @method W3CDOMNode.getNodeValue - Java style gettor for .NodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMNode.prototype.getNodeValue = function W3CDOMNode_getNodeValue() {
  return this.nodeValue;
};

/**
 * @method W3CDOMNode.setNodeValue - Java style settor for .NodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  nodeValue : string - unique internal id
 */
W3CDOMNode.prototype.setNodeValue = function W3CDOMNode_setNodeValue(nodeValue) {
  // throw Exception if W3CDOMNode is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  this.nodeValue = nodeValue;
};

/**
 * @method W3CDOMNode.getNodeType - Java style gettor for .nodeType
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : int
 */
W3CDOMNode.prototype.getNodeType = function W3CDOMNode_getNodeType() {
  return this.nodeType;
};

/**
 * @method W3CDOMNode.getParentNode - Java style gettor for .parentNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.getParentNode = function W3CDOMNode_getParentNode() {
  return this.parentNode;
};

/**
 * @method W3CDOMNode.getChildNodes - Java style gettor for .childNodes
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNodeList
 */
W3CDOMNode.prototype.getChildNodes = function W3CDOMNode_getChildNodes() {
  return this.childNodes;
};

/**
 * @method W3CDOMNode.getFirstChild - Java style gettor for .firstChild
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.getFirstChild = function W3CDOMNode_getFirstChild() {
  return this.firstChild;
};

/**
 * @method W3CDOMNode.getLastChild - Java style gettor for .lastChild
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.getLastChild = function W3CDOMNode_getLastChild() {
  return this.lastChild;
};

/**
 * @method W3CDOMNode.getPreviousSibling - Java style gettor for .previousSibling
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.getPreviousSibling = function W3CDOMNode_getPreviousSibling() {
  return this.previousSibling;
};

/**
 * @method W3CDOMNode.getNextSibling - Java style gettor for .nextSibling
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.getNextSibling = function W3CDOMNode_getNextSibling() {
  return this.nextSibling;
};

/**
 * @method W3CDOMNode.getAttributes - Java style gettor for .attributes
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMNamedNodeList
 */
W3CDOMNode.prototype.getAttributes = function W3CDOMNode_getAttributes() {
  return this.attributes;
};

/**
 * @method W3CDOMNode.getOwnerDocument - Java style gettor for .ownerDocument
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMDocument
 */
W3CDOMNode.prototype.getOwnerDocument = function W3CDOMNode_getOwnerDocument() {
  return this.ownerDocument;
};

/**
 * @method W3CDOMNode.getNamespaceURI - Java style gettor for .namespaceURI
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : String
 */
W3CDOMNode.prototype.getNamespaceURI = function W3CDOMNode_getNamespaceURI() {
  return this.namespaceURI;
};

/**
 * @method W3CDOMNode.getPrefix - Java style gettor for .prefix
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : String
 */
W3CDOMNode.prototype.getPrefix = function W3CDOMNode_getPrefix() {
  return this.prefix;
};

/**
 * @method W3CDOMNode.setPrefix - Java style settor for .prefix
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param   prefix : String
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Node is readonly.
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 * @throws : W3CDOMException - NAMESPACE_ERR: Raised if the Namespace is invalid
 *
 */
W3CDOMNode.prototype.setPrefix = function W3CDOMNode_setPrefix(prefix) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if W3CDOMNode is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if the prefix string contains an illegal character
    if (!this.ownerDocument.implementation._isValidName(prefix)) {
      throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
    }

    // throw Exception if the Namespace is invalid;
    //  if the specified prefix is malformed,
    //  if the namespaceURI of this node is null,
    //  if the specified prefix is "xml" and the namespaceURI of this node is
    //   different from "http://www.w3.org/XML/1998/namespace",
    if (!this.ownerDocument._isValidNamespace(this.namespaceURI, prefix +":"+ this.localName)) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }

    // throw Exception if we are trying to make the attribute look like a namespace declaration;
    //  if this node is an attribute and the specified prefix is "xmlns"
    //   and the namespaceURI of this node is different from "http://www.w3.org/2000/xmlns/",
    if ((prefix == "xmlns") && (this.namespaceURI != "http://www.w3.org/2000/xmlns/")) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }

    // throw Exception if we are trying to make the attribute look like a default namespace declaration;
    //  if this node is an attribute and the qualifiedName of this node is "xmlns" [Namespaces].
    if ((prefix == "") && (this.localName == "xmlns")) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }
  }

  // update prefix
  this.prefix = prefix;

  // update nodeName (QName)
  if (this.prefix != "") {
    this.nodeName = this.prefix +":"+ this.localName;
  }
  else {
    this.nodeName = this.localName;  // no prefix, therefore nodeName is simply localName
  }
};

/**
 * @method W3CDOMNode.getLocalName - Java style gettor for .localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : String
 */
W3CDOMNode.prototype.getLocalName = function W3CDOMNode_getLocalName() {
  return this.localName;
};

/**
 * @method W3CDOMNode.insertBefore - Inserts the node newChild before the existing child node refChild.
 *   If refChild is null, insert newChild at the end of the list of children.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild : W3CDOMNode - The node to insert.
 * @param  refChild : W3CDOMNode - The reference node, i.e., the node before which the new node must be inserted
 *
 * @throws : W3CDOMException - HIERARCHY_REQUEST_ERR: Raised if the node to insert is one of this node's ancestors
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Node is readonly.
 * @throws : W3CDOMException - NOT_FOUND_ERR: Raised if there is no node named name in this map.
 *
 * @return : W3CDOMNode - The node being inserted.
 */
W3CDOMNode.prototype.insertBefore = function W3CDOMNode_insertBefore(newChild, refChild) {
  var prevNode;

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if W3CDOMNode is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if newChild was not created by this Document
    if (this.ownerDocument != newChild.ownerDocument) {
      throw(new W3CDOMException(W3CDOMException.WRONG_DOCUMENT_ERR));
    }

    // throw Exception if the node is an ancestor
    if (this._isAncestor(newChild)) {
      throw(new W3CDOMException(W3CDOMException.HIERARCHY_REQUEST_ERR));
    }
  }

  if (refChild) {                                // if refChild is specified, insert before it
    // find index of refChild
    var itemIndex = this.childNodes._findItemIndex(refChild._id);

    // throw Exception if there is no child node with this id
    if (this.ownerDocument.implementation.errorChecking && (itemIndex < 0)) {
      throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
    }

    // if the newChild is already in the tree,
    var newChildParent = newChild.parentNode;
    if (newChildParent) {
      // remove it
      newChildParent.removeChild(newChild);
    }

    // insert newChild into childNodes
    this.childNodes._insertBefore(newChild, this.childNodes._findItemIndex(refChild._id));

    // do node pointer surgery
    prevNode = refChild.previousSibling;

    // handle DocumentFragment
    if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {
      if (newChild.childNodes._nodes.length > 0) {
        // set the parentNode of DocumentFragment's children
        for (var ind = 0; ind < newChild.childNodes._nodes.length; ind++) {
          newChild.childNodes._nodes[ind].parentNode = this;
        }

        // link refChild to last child of DocumentFragment
        refChild.previousSibling = newChild.childNodes._nodes[newChild.childNodes._nodes.length-1];
      }
    }
    else {
      newChild.parentNode = this;                // set the parentNode of the newChild
      refChild.previousSibling = newChild;       // link refChild to newChild
    }
  }
  else {                                         // otherwise, append to end
    prevNode = this.lastChild;
    this.appendChild(newChild);
  }

  if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {
    // do node pointer surgery for DocumentFragment
    if (newChild.childNodes._nodes.length > 0) {
      if (prevNode) {
        prevNode.nextSibling = newChild.childNodes._nodes[0];
      }
      else {                                         // this is the first child in the list
        this.firstChild = newChild.childNodes._nodes[0];
      }

      newChild.childNodes._nodes[0].previousSibling = prevNode;
      newChild.childNodes._nodes[newChild.childNodes._nodes.length-1].nextSibling = refChild;
    }
  }
  else {
    // do node pointer surgery for newChild
    if (prevNode) {
      prevNode.nextSibling = newChild;
    }
    else {                                         // this is the first child in the list
      this.firstChild = newChild;
    }

    newChild.previousSibling = prevNode;
    newChild.nextSibling     = refChild;
  }

  return newChild;
};

/**
 * @method W3CDOMNode.replaceChild - Replaces the child node oldChild with newChild in the list of children,
 *   and returns the oldChild node.
 *   If the newChild is already in the tree, it is first removed.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild : W3CDOMNode - The node to insert.
 * @param  oldChild : W3CDOMNode - The node being replaced in the list.
 *
 * @throws : W3CDOMException - HIERARCHY_REQUEST_ERR: Raised if the node to insert is one of this node's ancestors
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Node is readonly.
 * @throws : W3CDOMException - NOT_FOUND_ERR: Raised if there is no node named name in this map.
 *
 * @return : W3CDOMNode - The node that was replaced
 */
W3CDOMNode.prototype.replaceChild = function W3CDOMNode_replaceChild(newChild, oldChild) {
  var ret = null;

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if W3CDOMNode is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if newChild was not created by this Document
    if (this.ownerDocument != newChild.ownerDocument) {
      throw(new W3CDOMException(W3CDOMException.WRONG_DOCUMENT_ERR));
    }

    // throw Exception if the node is an ancestor
    if (this._isAncestor(newChild)) {
      throw(new W3CDOMException(W3CDOMException.HIERARCHY_REQUEST_ERR));
    }
  }

  // get index of oldChild
  var index = this.childNodes._findItemIndex(oldChild._id);

  // throw Exception if there is no child node with this id
  if (this.ownerDocument.implementation.errorChecking && (index < 0)) {
    throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
  }

  // if the newChild is already in the tree,
  var newChildParent = newChild.parentNode;
  if (newChildParent) {
    // remove it
    newChildParent.removeChild(newChild);
  }

  // add newChild to childNodes
  ret = this.childNodes._replaceChild(newChild, index);


  if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {
    // do node pointer surgery for Document Fragment
    if (newChild.childNodes._nodes.length > 0) {
      for (var ind = 0; ind < newChild.childNodes._nodes.length; ind++) {
        newChild.childNodes._nodes[ind].parentNode = this;
      }

      if (oldChild.previousSibling) {
        oldChild.previousSibling.nextSibling = newChild.childNodes._nodes[0];
      }
      else {
        this.firstChild = newChild.childNodes._nodes[0];
      }

      if (oldChild.nextSibling) {
        oldChild.nextSibling.previousSibling = newChild;
      }
      else {
        this.lastChild = newChild.childNodes._nodes[newChild.childNodes._nodes.length-1];
      }

      newChild.childNodes._nodes[0].previousSibling = oldChild.previousSibling;
      newChild.childNodes._nodes[newChild.childNodes._nodes.length-1].nextSibling = oldChild.nextSibling;
    }
  }
  else {
    // do node pointer surgery for newChild
    newChild.parentNode = this;

    if (oldChild.previousSibling) {
      oldChild.previousSibling.nextSibling = newChild;
    }
    else {
      this.firstChild = newChild;
    }
    if (oldChild.nextSibling) {
      oldChild.nextSibling.previousSibling = newChild;
    }
    else {
      this.lastChild = newChild;
    }
    newChild.previousSibling = oldChild.previousSibling;
    newChild.nextSibling = oldChild.nextSibling;
  }
  return ret;
};

/**
 * @method W3CDOMNode.removeChild - Removes the child node indicated by oldChild from the list of children, and returns it.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  oldChild : W3CDOMNode - The node being removed.
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Node is readonly.
 * @throws : W3CDOMException - NOT_FOUND_ERR: Raised if there is no node named name in this map.
 *
 * @return : W3CDOMNode - The node being removed.
 */
W3CDOMNode.prototype.removeChild = function W3CDOMNode_removeChild(oldChild) {
  // throw Exception if W3CDOMNamedNodeMap is readonly
  if (this.ownerDocument.implementation.errorChecking && (this._readonly || oldChild._readonly)) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // get index of oldChild
  var itemIndex = this.childNodes._findItemIndex(oldChild._id);

  // throw Exception if there is no child node with this id
  if (this.ownerDocument.implementation.errorChecking && (itemIndex < 0)) {
    throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
  }

  // remove oldChild from childNodes
  this.childNodes._removeChild(itemIndex);

  // do node pointer surgery
  oldChild.parentNode = null;

  if (oldChild.previousSibling) {
    oldChild.previousSibling.nextSibling = oldChild.nextSibling;
  }
  else {
    this.firstChild = oldChild.nextSibling;
  }
  if (oldChild.nextSibling) {
    oldChild.nextSibling.previousSibling = oldChild.previousSibling;
  }
  else {
    this.lastChild = oldChild.previousSibling;
  }

  oldChild.previousSibling = null;
  oldChild.nextSibling = null;
  return oldChild;
};

/**
 * @method W3CDOMNode.appendChild - Adds the node newChild to the end of the list of children of this node.
 *   If the newChild is already in the tree, it is first removed.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newChild : W3CDOMNode - The node to add
 *
 * @throws : W3CDOMException - HIERARCHY_REQUEST_ERR: Raised if the node to insert is one of this node's ancestors
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Node is readonly.
 *
 * @return : W3CDOMNode - The node added
 */
W3CDOMNode.prototype.appendChild = function W3CDOMNode_appendChild(newChild) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if Node is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if arg was not created by this Document
    if (this.ownerDocument != newChild.ownerDocument) {
      throw(new W3CDOMException(W3CDOMException.WRONG_DOCUMENT_ERR));
    }

    // throw Exception if the node is an ancestor
    if (this._isAncestor(newChild)) {
      throw(new W3CDOMException(W3CDOMException.HIERARCHY_REQUEST_ERR));
    }
  }

  // if the newChild is already in the tree,
  var newChildParent = newChild.parentNode;
  if (newChildParent) {
    // remove it
    newChildParent.removeChild(newChild);
  }

  // add newChild to childNodes
  this.childNodes._appendChild(newChild);

  if (newChild.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT_NODE) {
    // do node pointer surgery for DocumentFragment
    if (newChild.childNodes._nodes.length > 0) {
      for (var ind = 0; ind < newChild.childNodes._nodes.length; ind++) {
        newChild.childNodes._nodes[ind].parentNode = this;
      }

      if (this.lastChild) {
        this.lastChild.nextSibling = newChild.childNodes._nodes[0];
        newChild.childNodes._nodes[0].previousSibling = this.lastChild;
        this.lastChild = newChild.childNodes._nodes[newChild.childNodes._nodes.length-1];
      }
      else {
        this.lastChild = newChild.childNodes._nodes[newChild.childNodes._nodes.length-1];
        this.firstChild = newChild.childNodes._nodes[0];
      }
    }
  }
  else {
    // do node pointer surgery for newChild
    newChild.parentNode = this;
    if (this.lastChild) {
      this.lastChild.nextSibling = newChild;
      newChild.previousSibling = this.lastChild;
      this.lastChild = newChild;
    }
    else {
      this.lastChild = newChild;
      this.firstChild = newChild;
    }
  }

  return newChild;
};

/**
 * @method W3CDOMNode.hasChildNodes - This is a convenience method to allow easy determination of whether a node has any children.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : boolean - true if the node has any children, false if the node has no children
 */
W3CDOMNode.prototype.hasChildNodes = function W3CDOMNode_hasChildNodes() {
  return (this.childNodes.length > 0);
};

/**
 * @method W3CDOMNode.cloneNode - Returns a duplicate of this node, i.e., serves as a generic copy constructor for nodes.
 *   The duplicate node has no parent (parentNode returns null.).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  deep : boolean - If true, recursively clone the subtree under the specified node;
 *   if false, clone only the node itself (and its attributes, if it is an Element).
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.cloneNode = function W3CDOMNode_cloneNode(deep) {
  // use importNode to clone this Node
  //do not throw any exceptions
  try {
     return this.ownerDocument.importNode(this, deep);
  }
  catch (e) {
     //there shouldn't be any exceptions, but if there are, return null
     return null;
  }
};

/**
 * @method W3CDOMNode.normalize - Puts all Text nodes in the full depth of the sub-tree underneath this Element into a "normal" form
 *   where only markup (e.g., tags, comments, processing instructions, CDATA sections, and entity references) separates Text nodes,
 *   i.e., there are no adjacent Text nodes.
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 */
W3CDOMNode.prototype.normalize = function W3CDOMNode_normalize() {
  var inode;
  var nodesToRemove = new W3CDOMNodeList();

  if (this.nodeType == W3CDOMNode.ELEMENT_NODE || this.nodeType == W3CDOMNode.DOCUMENT_NODE) {
    var adjacentTextNode = null;

    // loop through all childNodes
    for(var i = 0; i < this.childNodes.length; i++) {
      inode = this.childNodes.item(i);

      if (inode.nodeType == W3CDOMNode.TEXT_NODE) { // this node is a text node
        if (inode.length < 1) {                  // this text node is empty
          nodesToRemove._appendChild(inode);      // add this node to the list of nodes to be remove
        }
        else {
          if (adjacentTextNode) {                // if previous node was also text
            adjacentTextNode.appendData(inode.data);     // merge the data in adjacent text nodes
            nodesToRemove._appendChild(inode);    // add this node to the list of nodes to be removed
          }
          else {
              adjacentTextNode = inode;              // remember this node for next cycle
          }
        }
      }
      else {
        adjacentTextNode = null;                 // (soon to be) previous node is not a text node
        inode.normalize();                       // normalise non Text childNodes
      }
    }

    // remove redundant Text Nodes
    for(var i = 0; i < nodesToRemove.length; i++) {
      inode = nodesToRemove.item(i);
      inode.parentNode.removeChild(inode);
    }
  }
};

/**
 * @method W3CDOMNode.isSupported - Test if the W3CDOM implementation implements a specific feature
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  feature : string - The package name of the feature to test. the legal only values are "XML" and "CORE" (case-insensitive).
 * @param  version : string - This is the version number of the package name to test. In Level 1, this is the string "1.0".
 *
 * @return : boolean
 */
W3CDOMNode.prototype.isSupported = function W3CDOMNode_isSupported(feature, version) {
  // use Implementation.hasFeature to determin if this feature is supported
  return this.ownerDocument.implementation.hasFeature(feature, version);
}

/**
 * @method W3CDOMNode.getElementsByTagName - Returns a NodeList of all the Elements with a given tag name
 *   in the order in which they would be encountered in a preorder traversal of the Document tree.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  tagname : string - The name of the tag to match on. The special value "*" matches all tags
 *
 * @return : W3CDOMNodeList
 */
W3CDOMNode.prototype.getElementsByTagName = function W3CDOMNode_getElementsByTagName(tagname) {
  // delegate to _getElementsByTagNameRecursive
  return this._getElementsByTagNameRecursive(tagname, new W3CDOMNodeList(this.ownerDocument));
};

/**
 * @method W3CDOMNode._getElementsByTagNameRecursive - implements getElementsByTagName()
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  tagname  : string      - The name of the tag to match on. The special value "*" matches all tags
 * @param  nodeList : W3CDOMNodeList - The accumulating list of matching nodes
 *
 * @return : W3CDOMNodeList
 */
W3CDOMNode.prototype._getElementsByTagNameRecursive = function W3CDOMNode__getElementsByTagNameRecursive(tagname, nodeList) {
  if (this.nodeType == W3CDOMNode.ELEMENT_NODE || this.nodeType == W3CDOMNode.DOCUMENT_NODE) {

    if((this.nodeName == tagname) || (tagname == "*")) {
      nodeList._appendChild(this);               // add matching node to nodeList
    }

    // recurse childNodes
    for(var i = 0; i < this.childNodes.length; i++) {
      nodeList = this.childNodes.item(i)._getElementsByTagNameRecursive(tagname, nodeList);
    }
  }

  return nodeList;
};

/**
 * @method W3CDOMNode.getXML - Returns the String XML of the node and all of its children
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string - XML String of the XML of the node and all of its children
 */
W3CDOMNode.prototype.getXML = function W3CDOMNode_getXML() {
  return this.toString();
}


/**
 * @method W3CDOMNode.getElementsByTagNameNS - Returns a NodeList of all the Elements with a given namespaceURI and localName
 *   in the order in which they would be encountered in a preorder traversal of the Document tree.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : W3CDOMNodeList
 */
W3CDOMNode.prototype.getElementsByTagNameNS = function W3CDOMNode_getElementsByTagNameNS(namespaceURI, localName) {
  // delegate to _getElementsByTagNameNSRecursive
  return this._getElementsByTagNameNSRecursive(namespaceURI, localName, new W3CDOMNodeList(this.ownerDocument));
};

/**
 * @method W3CDOMNode._getElementsByTagNameNSRecursive - implements getElementsByTagName()
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 * @param  nodeList     : W3CDOMNodeList - The accumulating list of matching nodes
 *
 * @return : W3CDOMNodeList
 */
W3CDOMNode.prototype._getElementsByTagNameNSRecursive = function W3CDOMNode__getElementsByTagNameNSRecursive(namespaceURI, localName, nodeList) {
  if (this.nodeType == W3CDOMNode.ELEMENT_NODE || this.nodeType == W3CDOMNode.DOCUMENT_NODE) {

    if (((this.namespaceURI == namespaceURI) || (namespaceURI == "*")) && ((this.localName == localName) || (localName == "*"))) {
      nodeList._appendChild(this);               // add matching node to nodeList
    }

    // recurse childNodes
    for(var i = 0; i < this.childNodes.length; i++) {
      nodeList = this.childNodes.item(i)._getElementsByTagNameNSRecursive(namespaceURI, localName, nodeList);
    }
  }

  return nodeList;
};

/**
 * @method W3CDOMNode._isAncestor - returns true if node is ancestor of this
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  node         : W3CDOMNode - The candidate ancestor node
 *
 * @return : boolean
 */
W3CDOMNode.prototype._isAncestor = function W3CDOMNode__isAncestor(node) {
  // if this node matches, return true,
  // otherwise recurse up (if there is a parentNode)
  return ((this == node) || ((this.parentNode) && (this.parentNode._isAncestor(node))));
}

/**
 * @method W3CDOMNode.importNode - Imports a node from another document to this document.
 *   The returned node has no parent; (parentNode is null).
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  importedNode : Node - The Node to be imported
 * @param  deep         : boolean - If true, recursively clone the subtree under the specified node;
 *   if false, clone only the node itself (and its attributes, if it is an Element).
 *
 * @return : W3CDOMNode
 */
W3CDOMNode.prototype.importNode = function W3CDOMNode_importNode(importedNode, deep) {
  var importNode;

  //there is no need to perform namespace checks since everything has already gone through them
  //in order to have gotten into the W3CDOM in the first place. The following line
  //turns namespace checking off in ._isValidNamespace
  this.getOwnerDocument()._performingImportNodeOperation = true;

  try {
    if (importedNode.nodeType == W3CDOMNode.ELEMENT_NODE) {
        if (!this.ownerDocument.implementation.namespaceAware) {
        // create a local Element (with the name of the importedNode)
        importNode = this.ownerDocument.createElement(importedNode.tagName);

        // create attributes matching those of the importedNode
        for(var i = 0; i < importedNode.attributes.length; i++) {
            importNode.setAttribute(importedNode.attributes.item(i).name, importedNode.attributes.item(i).value);
        }
        }
        else {
        // create a local Element (with the name & namespaceURI of the importedNode)
        importNode = this.ownerDocument.createElementNS(importedNode.namespaceURI, importedNode.nodeName);

        // create attributes matching those of the importedNode
        for(var i = 0; i < importedNode.attributes.length; i++) {
            importNode.setAttributeNS(importedNode.attributes.item(i).namespaceURI, importedNode.attributes.item(i).name, importedNode.attributes.item(i).value);
        }

        // create namespace definitions matching those of the importedNode
        for(var i = 0; i < importedNode._namespaces.length; i++) {
            importNode._namespaces._nodes[i] = this.ownerDocument.createNamespace(importedNode._namespaces.item(i).localName);
            importNode._namespaces._nodes[i].setValue(importedNode._namespaces.item(i).value);
        }
        }
    }
    else if (importedNode.nodeType == W3CDOMNode.ATTRIBUTE_NODE) {
        if (!this.ownerDocument.implementation.namespaceAware) {
        // create a local Attribute (with the name of the importedAttribute)
        importNode = this.ownerDocument.createAttribute(importedNode.name);
        }
        else {
        // create a local Attribute (with the name & namespaceURI of the importedAttribute)
        importNode = this.ownerDocument.createAttributeNS(importedNode.namespaceURI, importedNode.nodeName);

        // create namespace definitions matching those of the importedAttribute
        for(var i = 0; i < importedNode._namespaces.length; i++) {
            importNode._namespaces._nodes[i] = this.ownerDocument.createNamespace(importedNode._namespaces.item(i).localName);
            importNode._namespaces._nodes[i].setValue(importedNode._namespaces.item(i).value);
        }
        }

        // set the value of the local Attribute to match that of the importedAttribute
        importNode.setValue(importedNode.value);
    }
    else if (importedNode.nodeType == W3CDOMNode.DOCUMENT_FRAGMENT) {
        // create a local DocumentFragment
        importNode = this.ownerDocument.createDocumentFragment();
    }
    else if (importedNode.nodeType == W3CDOMNode.NAMESPACE_NODE) {
        // create a local NamespaceNode (with the same name & value as the importedNode)
        importNode = this.ownerDocument.createNamespace(importedNode.nodeName);
        importNode.setValue(importedNode.value);
    }
    else if (importedNode.nodeType == W3CDOMNode.TEXT_NODE) {
        // create a local TextNode (with the same data as the importedNode)
        importNode = this.ownerDocument.createTextNode(importedNode.data);
    }
    else if (importedNode.nodeType == W3CDOMNode.CDATA_SECTION_NODE) {
        // create a local CDATANode (with the same data as the importedNode)
        importNode = this.ownerDocument.createCDATASection(importedNode.data);
    }
    else if (importedNode.nodeType == W3CDOMNode.PROCESSING_INSTRUCTION_NODE) {
        // create a local ProcessingInstruction (with the same target & data as the importedNode)
        importNode = this.ownerDocument.createProcessingInstruction(importedNode.target, importedNode.data);
    }
    else if (importedNode.nodeType == W3CDOMNode.COMMENT_NODE) {
        // create a local Comment (with the same data as the importedNode)
        importNode = this.ownerDocument.createComment(importedNode.data);
    }
    else {  // throw Exception if nodeType is not supported
        throw(new W3CDOMException(W3CDOMException.NOT_SUPPORTED_ERR));
    }

    if (deep) {                                    // recurse childNodes
        for(var i = 0; i < importedNode.childNodes.length; i++) {
        importNode.appendChild(this.ownerDocument.importNode(importedNode.childNodes.item(i), true));
        }
    }

    //reset _performingImportNodeOperation
    this.getOwnerDocument()._performingImportNodeOperation = false;
    return importNode;
  }
  catch (eAny) {
    //reset _performingImportNodeOperation
    this.getOwnerDocument()._performingImportNodeOperation = false;

    //re-throw the exception
    throw eAny;
  }//djotemp
};

/**
 * @method W3CDOMNode.escapeString - escape special characters
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  str : string - The string to be escaped
 *
 * @return : string - The escaped string
 */
W3CDOMNode.prototype.__escapeString = function W3CDOMNode__escapeString(str) {

  //the sax processor already has this function. Just wrap it
  return __escapeString(str);
};

/**
 * @method W3CDOMNode.unescapeString - unescape special characters
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  str : string - The string to be unescaped
 *
 * @return : string - The unescaped string
 */
W3CDOMNode.prototype.__unescapeString = function W3CDOMNode__unescapeString(str) {

  //the sax processor already has this function. Just wrap it
  return __unescapeString(str);
};



/**
 * @class  W3CDOMDocument - The Document interface represents the entire HTML or XML document.
 *   Conceptually, it is the root of the document tree, and provides the primary access to the document's data.
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  implementation : W3CDOMImplementation - the creator Implementation
 */
W3CDOMDocument = function(implementation) {
  this._class = addClass(this._class, "W3CDOMDocument");
  this.W3CDOMNode = W3CDOMNode;
  this.W3CDOMNode(this);

  this.doctype = null;                           // The Document Type Declaration (see DocumentType) associated with this document
  this.implementation = implementation;          // The W3CDOMImplementation object that handles this document.
  this.documentElement = null;                   // This is a convenience attribute that allows direct access to the child node that is the root element of the document
  this.all  = new Array();                       // The list of all Elements

  this.nodeName  = "#document";
  this.nodeType = W3CDOMNode.DOCUMENT_NODE;
  this._id = 0;
  this._lastId = 0;
  this._parseComplete = false;                   // initially false, set to true by parser

  this.ownerDocument = this;

  this._performingImportNodeOperation = false;
};
W3CDOMDocument.prototype = new W3CDOMNode;

/**
 * @method W3CDOMDocument.getDoctype - Java style gettor for .doctype
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMDocument
 */
W3CDOMDocument.prototype.getDoctype = function W3CDOMDocument_getDoctype() {
  return this.doctype;
};

/**
 * @method W3CDOMDocument.getImplementation - Java style gettor for .implementation
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMImplementation
 */
W3CDOMDocument.prototype.getImplementation = function W3CDOMDocument_implementation() {
  return this.implementation;
};

/**
 * @method W3CDOMDocument.getDocumentElement - Java style gettor for .documentElement
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMDocumentElement
 */
W3CDOMDocument.prototype.getDocumentElement = function W3CDOMDocument_getDocumentElement() {
  return this.documentElement;
};

/**
 * @method W3CDOMDocument.createElement - Creates an element of the type specified.
 *   Note that the instance returned implements the Element interface,
 *   so attributes can be specified directly on the returned object.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  tagName : string - The name of the element type to instantiate.
 *
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 *
 * @return : W3CDOMElement - The new Element object.
 */
W3CDOMDocument.prototype.createElement = function W3CDOMDocument_createElement(tagName) {
  // throw Exception if the tagName string contains an illegal character
  if (this.ownerDocument.implementation.errorChecking && (!this.ownerDocument.implementation._isValidName(tagName))) {
    throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
  }

  // create W3CDOMElement specifying 'this' as ownerDocument
  var node = new W3CDOMElement(this);

  // assign values to properties (and aliases)
  node.tagName  = tagName;
  node.nodeName = tagName;

  // add Element to 'all' collection
  this.all[this.all.length] = node;

  return node;
};

/**
 * @method W3CDOMDocument.createDocumentFragment - CCreates an empty DocumentFragment object.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : W3CDOMDocumentFragment - The new DocumentFragment object
 */
W3CDOMDocument.prototype.createDocumentFragment = function W3CDOMDocument_createDocumentFragment() {
  // create W3CDOMDocumentFragment specifying 'this' as ownerDocument
  var node = new W3CDOMDocumentFragment(this);

  return node;
};

/**
 * @method W3CDOMDocument.createTextNode - Creates a Text node given the specified string.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - The data for the node.
 *
 * @return : W3CDOMText - The new Text object.
 */
W3CDOMDocument.prototype.createTextNode = function W3CDOMDocument_createTextNode(data) {
  // create W3CDOMText specifying 'this' as ownerDocument
  var node = new W3CDOMText(this);

  // assign values to properties (and aliases)
  node.data      = data;
  node.nodeValue = data;

  // set initial length
  node.length    = data.length;

  return node;
};

/**
 * @method W3CDOMDocument.createComment - Creates a Text node given the specified string.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - The data for the node.
 *
 * @return : W3CDOMComment - The new Comment object.
 */
W3CDOMDocument.prototype.createComment = function W3CDOMDocument_createComment(data) {
  // create W3CDOMComment specifying 'this' as ownerDocument
  var node = new W3CDOMComment(this);

  // assign values to properties (and aliases)
  node.data      = data;
  node.nodeValue = data;

  // set initial length
  node.length    = data.length;

  return node;
};

/**
 * @method W3CDOMDocument.createCDATASection - Creates a CDATASection node whose value is the specified string.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - The data for the node.
 *
 * @return : W3CDOMCDATASection - The new CDATASection object.
 */
W3CDOMDocument.prototype.createCDATASection = function W3CDOMDocument_createCDATASection(data) {
  // create W3CDOMCDATASection specifying 'this' as ownerDocument
  var node = new W3CDOMCDATASection(this);

  // assign values to properties (and aliases)
  node.data      = data;
  node.nodeValue = data;

  // set initial length
  node.length    = data.length;

  return node;
};

/**
 * @method W3CDOMDocument.createProcessingInstruction - Creates a ProcessingInstruction node given the specified target and data strings.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  target : string - The target part of the processing instruction.
 * @param  data   : string - The data for the node.
 *
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 *
 * @return : W3CDOMProcessingInstruction - The new ProcessingInstruction object.
 */
W3CDOMDocument.prototype.createProcessingInstruction = function W3CDOMDocument_createProcessingInstruction(target, data) {
  // throw Exception if the target string contains an illegal character
  if (this.ownerDocument.implementation.errorChecking && (!this.implementation._isValidName(target))) {
    throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
  }

  // create W3CDOMProcessingInstruction specifying 'this' as ownerDocument
  var node = new W3CDOMProcessingInstruction(this);

  // assign values to properties (and aliases)
  node.target    = target;
  node.nodeName  = target;
  node.data      = data;
  node.nodeValue = data;

  // set initial length
  node.length    = data.length;

  return node;
};

/**
 * @method W3CDOMDocument.createAttribute - Creates an Attr of the given name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - The name of the attribute.
 *
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 *
 * @return : W3CDOMAttr - The new Attr object.
 */
W3CDOMDocument.prototype.createAttribute = function W3CDOMDocument_createAttribute(name) {
  // throw Exception if the name string contains an illegal character
  if (this.ownerDocument.implementation.errorChecking && (!this.ownerDocument.implementation._isValidName(name))) {
    throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
  }

  // create W3CDOMAttr specifying 'this' as ownerDocument
  var node = new W3CDOMAttr(this);

  // assign values to properties (and aliases)
  node.name     = name;
  node.nodeName = name;

  return node;
};

/**
 * @method W3CDOMDocument.createElementNS - Creates an element of the type specified,
 *   within the specified namespace.
 *   Note that the instance returned implements the Element interface,
 *   so attributes can be specified directly on the returned object.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI  : string - The namespace URI of the element.
 * @param  qualifiedName : string - The qualified name of the element type to instantiate.
 *
 * @throws : W3CDOMException - NAMESPACE_ERR: Raised if the Namespace is invalid
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 *
 * @return : W3CDOMElement - The new Element object.
 */
W3CDOMDocument.prototype.createElementNS = function W3CDOMDocument_createElementNS(namespaceURI, qualifiedName) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if the Namespace is invalid
    if (!this.ownerDocument._isValidNamespace(namespaceURI, qualifiedName)) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }

    // throw Exception if the qualifiedName string contains an illegal character
    if (!this.ownerDocument.implementation._isValidName(qualifiedName)) {
      throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
    }
  }

  // create W3CDOMElement specifying 'this' as ownerDocument
  var node  = new W3CDOMElement(this);
  var qname = this.implementation._parseQName(qualifiedName);

  // assign values to properties (and aliases)
  node.nodeName     = qualifiedName;
  node.namespaceURI = namespaceURI;
  node.prefix       = qname.prefix;
  node.localName    = qname.localName;
  node.tagName      = qualifiedName;

  // add Element to 'all' collection
  this.all[this.all.length] = node;

  return node;
};

/**
 * @method W3CDOMDocument.createAttributeNS - Creates an Attr of the given name
 *   within the specified namespace.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI  : string - The namespace URI of the attribute.
 * @param  qualifiedName : string - The qualified name of the attribute.
 *
 * @throws : W3CDOMException - NAMESPACE_ERR: Raised if the Namespace is invalid
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 *
 * @return : W3CDOMAttr - The new Attr object.
 */
W3CDOMDocument.prototype.createAttributeNS = function W3CDOMDocument_createAttributeNS(namespaceURI, qualifiedName) {
  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if the Namespace is invalid
    if (!this.ownerDocument._isValidNamespace(namespaceURI, qualifiedName, true)) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }

    // throw Exception if the qualifiedName string contains an illegal character
    if (!this.ownerDocument.implementation._isValidName(qualifiedName)) {
      throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
    }
  }

  // create W3CDOMAttr specifying 'this' as ownerDocument
  var node  = new W3CDOMAttr(this);
  var qname = this.implementation._parseQName(qualifiedName);

  // assign values to properties (and aliases)
  node.nodeName     = qualifiedName
  node.namespaceURI = namespaceURI
  node.prefix       = qname.prefix;
  node.localName    = qname.localName;
  node.name         = qualifiedName
  node.nodeValue    = "";

  return node;
};

/**
 * @method W3CDOMDocument.createNamespace - Creates an Namespace of the given name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  qualifiedName : string - The qualified name of the attribute.
 *
 * @return : W3CDOMNamespace - The new Namespace object.
 */
W3CDOMDocument.prototype.createNamespace = function W3CDOMDocument_createNamespace(qualifiedName) {
  // create W3CDOMNamespace specifying 'this' as ownerDocument
  var node  = new W3CDOMNamespace(this);
  var qname = this.implementation._parseQName(qualifiedName);

  // assign values to properties (and aliases)
  node.nodeName     = qualifiedName
  node.prefix       = qname.prefix;
  node.localName    = qname.localName;
  node.name         = qualifiedName
  node.nodeValue    = "";

  return node;
};

/**
 * @method W3CDOMDocument.getElementById - Return the Element whose ID is given by elementId
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  elementId : string - The unique ID of the Element
 *
 * @return : W3CDOMElement - The requested W3CDOMElement
 */
W3CDOMDocument.prototype.getElementById = function W3CDOMDocument_getElementById(elementId) {
//  return this._ids[elementId];
  retNode = null;

  // loop through all Elements in the 'all' collection
  for (var i=0; i < this.all.length; i++) {
    var node = this.all[i];

    // if id matches & node is alive (ie, connected (in)directly to the documentElement)
    if ((node.id == elementId) && (node._isAncestor(node.ownerDocument.documentElement))) {
      retNode = node;
      break;
    }
  }

  return retNode;
};



/**
 * @method W3CDOMDocument._genId - generate a unique internal id
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string - The unique (serial) id
 */
W3CDOMDocument.prototype._genId = function W3CDOMDocument__genId() {
  this._lastId += 1;                             // increment lastId (to generate unique id)

  return this._lastId;
};


/**
 * @method W3CDOMDocument._isValidNamespace - test if Namespace is valid
 *  ie, not valid if;
 *    the qualifiedName is malformed, or
 *    the qualifiedName has a prefix and the namespaceURI is null, or
 *    the qualifiedName has a prefix that is "xml" and the namespaceURI is
 *     different from "http://www.w3.org/XML/1998/namespace" [Namespaces].
 *
 * @author Jon van Noort (jon@webarcana.com.au), David Joham (djoham@yahoo.com) and Scott Severtson
 *
 * @param  namespaceURI  : string - the namespace URI
 * @param  qualifiedName : string - the QName
 * @Param  isAttribute   : boolean - true, if the requesting node is an Attr
 *
 * @return : boolean
 */
W3CDOMDocument.prototype._isValidNamespace = function W3CDOMDocument__isValidNamespace(namespaceURI, qualifiedName, isAttribute) {

  if (this._performingImportNodeOperation == true) {
    //we're doing an importNode operation (or a cloneNode) - in both cases, there
    //is no need to perform any namespace checking since the nodes have to have been valid
    //to have gotten into the W3CDOM in the first place
    return true;
  }

  var valid = true;
  // parse QName
  var qName = this.implementation._parseQName(qualifiedName);


  //only check for namespaces if we're finished parsing
  if (this._parseComplete == true) {

    // if the qualifiedName is malformed
    if (qName.localName.indexOf(":") > -1 ){
        valid = false;
    }

    if ((valid) && (!isAttribute)) {
        // if the namespaceURI is not null
        if (!namespaceURI) {
        valid = false;
        }
    }

    // if the qualifiedName has a prefix
    if ((valid) && (qName.prefix == "")) {
        valid = false;
    }

  }

  // if the qualifiedName has a prefix that is "xml" and the namespaceURI is
  //  different from "http://www.w3.org/XML/1998/namespace" [Namespaces].
  if ((valid) && (qName.prefix == "xml") && (namespaceURI != "http://www.w3.org/XML/1998/namespace")) {
    valid = false;
  }

  return valid;
}

/**
 * @method W3CDOMDocument.toString - Serialize the document into an XML string
 *
 * @author David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMDocument.prototype.toString = function W3CDOMDocument_toString() {
  return "" + this.childNodes;
} // end function getXML


/**
 * @class  W3CDOMElement - By far the vast majority of objects (apart from text) that authors encounter
 *   when traversing a document are Element nodes.
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMElement = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMElement");
  this.W3CDOMNode  = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  this.tagName = "";                             // The name of the element.
  this.id = "";                                  // the ID of the element

  this.nodeType = W3CDOMNode.ELEMENT_NODE;
};
W3CDOMElement.prototype = new W3CDOMNode;

/**
 * @method W3CDOMElement.getTagName - Java style gettor for .TagName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMElement.prototype.getTagName = function W3CDOMElement_getTagName() {
  return this.tagName;
};

/**
 * @method W3CDOMElement.getAttribute - Retrieves an attribute value by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - The name of the attribute to retrieve
 *
 * @return : string - The Attr value as a string, or the empty string if that attribute does not have a specified value.
 */
W3CDOMElement.prototype.getAttribute = function W3CDOMElement_getAttribute(name) {
  var ret = "";

  // if attribute exists, use it
  var attr = this.attributes.getNamedItem(name);

  if (attr) {
    ret = attr.value;
  }

  return ret; // if Attribute exists, return its value, otherwise, return ""
};

/**
 * @method W3CDOMElement.setAttribute - Retrieves an attribute value by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name  : string - The name of the attribute to create or alter
 * @param  value : string - Value to set in string form
 *
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if the Attribute is readonly.
 */
W3CDOMElement.prototype.setAttribute = function W3CDOMElement_setAttribute(name, value) {
  // if attribute exists, use it
  var attr = this.attributes.getNamedItem(name);

  if (!attr) {
    attr = this.ownerDocument.createAttribute(name);  // otherwise create it
  }

  var value = new String(value);

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if Attribute is readonly
    if (attr._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if the value string contains an illegal character
    if (!this.ownerDocument.implementation._isValidString(value)) {
      throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
    }
  }

  if (this.ownerDocument.implementation._isIdDeclaration(name)) {
    this.id = value;  // cache ID for getElementById()
  }

  // assign values to properties (and aliases)
  attr.value     = value;
  attr.nodeValue = value;

  // update .specified
  if (value.length > 0) {
    attr.specified = true;
  }
  else {
    attr.specified = false;
  }

  // add/replace Attribute in NamedNodeMap
  this.attributes.setNamedItem(attr);
};

/**
 * @method W3CDOMElement.removeAttribute - Removes an attribute by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name  : string - The name of the attribute to remove
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if the Attrbute is readonly.
 */
W3CDOMElement.prototype.removeAttribute = function W3CDOMElement_removeAttribute(name) {
  // delegate to W3CDOMNamedNodeMap.removeNamedItem
  return this.attributes.removeNamedItem(name);
};

/**
 * @method W3CDOMElement.getAttributeNode - Retrieves an Attr node by name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name  : string - The name of the attribute to remove
 *
 * @return : W3CDOMAttr - The Attr node with the specified attribute name or null if there is no such attribute.
 */
W3CDOMElement.prototype.getAttributeNode = function W3CDOMElement_getAttributeNode(name) {
  // delegate to W3CDOMNamedNodeMap.getNamedItem
  return this.attributes.getNamedItem(name);
};

/**
 * @method W3CDOMElement.setAttributeNode - Adds a new attribute
 *   If an attribute with that name is already present in the element, it is replaced by the new one
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newAttr : W3CDOMAttr - The attribute node to be attached
 *
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Element is readonly.
 * @throws : W3CDOMException - INUSE_ATTRIBUTE_ERR: Raised if arg is an Attr that is already an attribute of another Element object.
 *
 * @return : W3CDOMAttr - If the newAttr attribute replaces an existing attribute with the same name,
 *   the previously existing Attr node is returned, otherwise null is returned.
 */
W3CDOMElement.prototype.setAttributeNode = function W3CDOMElement_setAttributeNode(newAttr) {
  // if this Attribute is an ID
  if (this.ownerDocument.implementation._isIdDeclaration(newAttr.name)) {
    this.id = newAttr.value;  // cache ID for getElementById()
  }

  // delegate to W3CDOMNamedNodeMap.setNamedItem
  return this.attributes.setNamedItem(newAttr);
};

/**
 * @method W3CDOMElement.removeAttributeNode - Removes the specified attribute
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  oldAttr  : W3CDOMAttr - The Attr node to remove from the attribute list
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Element is readonly.
 * @throws : W3CDOMException - INUSE_ATTRIBUTE_ERR: Raised if arg is an Attr that is already an attribute of another Element object.
 *
 * @return : W3CDOMAttr - The Attr node that was removed.
 */
W3CDOMElement.prototype.removeAttributeNode = function W3CDOMElement_removeAttributeNode(oldAttr) {
  // throw Exception if Attribute is readonly
  if (this.ownerDocument.implementation.errorChecking && oldAttr._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // get item index
  var itemIndex = this.attributes._findItemIndex(oldAttr._id);

  // throw Exception if node does not exist in this map
  if (this.ownerDocument.implementation.errorChecking && (itemIndex < 0)) {
    throw(new W3CDOMException(W3CDOMException.NOT_FOUND_ERR));
  }

  return this.attributes._removeChild(itemIndex);
};

/**
 * @method W3CDOMElement.getAttributeNS - Retrieves an attribute value by namespaceURI and localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : string - The Attr value as a string, or the empty string if that attribute does not have a specified value.
 */
W3CDOMElement.prototype.getAttributeNS = function W3CDOMElement_getAttributeNS(namespaceURI, localName) {
  var ret = "";

  // delegate to W3CDOMNAmedNodeMap.getNamedItemNS
  var attr = this.attributes.getNamedItemNS(namespaceURI, localName);


  if (attr) {
    ret = attr.value;
  }

  return ret;  // if Attribute exists, return its value, otherwise return ""
};

/**
 * @method W3CDOMElement.setAttributeNS - Sets an attribute value by namespaceURI and localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  qualifiedName : string - the qualified name of the required node
 * @param  value        : string - Value to set in string form
 *
 * @throws : W3CDOMException - INVALID_CHARACTER_ERR: Raised if the string contains an illegal character
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if the Attrbute is readonly.
 * @throws : W3CDOMException - NAMESPACE_ERR: Raised if the Namespace is invalid
 */
W3CDOMElement.prototype.setAttributeNS = function W3CDOMElement_setAttributeNS(namespaceURI, qualifiedName, value) {
  // call W3CDOMNamedNodeMap.getNamedItem
  var attr = this.attributes.getNamedItem(namespaceURI, qualifiedName);

  if (!attr) {  // if Attribute exists, use it
    // otherwise create it
    attr = this.ownerDocument.createAttributeNS(namespaceURI, qualifiedName);
  }

  var value = new String(value);

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if Attribute is readonly
    if (attr._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if the Namespace is invalid
    if (!this.ownerDocument._isValidNamespace(namespaceURI, qualifiedName)) {
      throw(new W3CDOMException(W3CDOMException.NAMESPACE_ERR));
    }

    // throw Exception if the value string contains an illegal character
    if (!this.ownerDocument.implementation._isValidString(value)) {
      throw(new W3CDOMException(W3CDOMException.INVALID_CHARACTER_ERR));
    }
  }

  // if this Attribute is an ID
  if (this.ownerDocument.implementation._isIdDeclaration(name)) {
    this.id = value;  // cache ID for getElementById()
  }

  // assign values to properties (and aliases)
  attr.value     = value;
  attr.nodeValue = value;

  // update .specified
  if (value.length > 0) {
    attr.specified = true;
  }
  else {
    attr.specified = false;
  }

  // delegate to W3CDOMNamedNodeMap.setNamedItem
  this.attributes.setNamedItemNS(attr);
};

/**
 * @method W3CDOMElement.removeAttributeNS - Removes an attribute by namespaceURI and localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if the Attrbute is readonly.
 *
 * @return : W3CDOMAttr
 */
W3CDOMElement.prototype.removeAttributeNS = function W3CDOMElement_removeAttributeNS(namespaceURI, localName) {
  // delegate to W3CDOMNamedNodeMap.removeNamedItemNS
  return this.attributes.removeNamedItemNS(namespaceURI, localName);
};

/**
 * @method W3CDOMElement.getAttributeNodeNS - Retrieves an Attr node by namespaceURI and localName
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : W3CDOMAttr - The Attr node with the specified attribute name or null if there is no such attribute.
 */
W3CDOMElement.prototype.getAttributeNodeNS = function W3CDOMElement_getAttributeNodeNS(namespaceURI, localName) {
  // delegate to W3CDOMNamedNodeMap.getNamedItemNS
  return this.attributes.getNamedItemNS(namespaceURI, localName);
};

/**
 * @method W3CDOMElement.setAttributeNodeNS - Adds a new attribute
 *   If an attribute with that name is already present in the element, it is replaced by the new one
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  newAttr      : W3CDOMAttr - the attribute node to be attached
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if the Attrbute is readonly.
 * @throws : W3CDOMException - WRONG_DOCUMENT_ERR: Raised if arg was created from a different document than the one that created this map.
 * @throws : W3CDOMException - INUSE_ATTRIBUTE_ERR: Raised if arg is an Attr that is already an attribute of another Element object.
 *  The W3CDOM user must explicitly clone Attr nodes to re-use them in other elements.
 *
 * @return : W3CDOMAttr - If the newAttr attribute replaces an existing attribute with the same name,
 *   the previously existing Attr node is returned, otherwise null is returned.
 */
W3CDOMElement.prototype.setAttributeNodeNS = function W3CDOMElement_setAttributeNodeNS(newAttr) {
  // if this Attribute is an ID
  if ((newAttr.prefix == "") &&  this.ownerDocument.implementation._isIdDeclaration(newAttr.name)) {
    this.id = newAttr.value;  // cache ID for getElementById()
  }

  // delegate to W3CDOMNamedNodeMap.setNamedItemNS
  return this.attributes.setNamedItemNS(newAttr);
};

/**
 * @method W3CDOMElement.hasAttribute - Returns true if specified node exists
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  name : string - the name of the required node
 *
 * @return : boolean
 */
W3CDOMElement.prototype.hasAttribute = function W3CDOMElement_hasAttribute(name) {
  // delegate to W3CDOMNamedNodeMap._hasAttribute
  return this.attributes._hasAttribute(name);
}

/**
 * @method W3CDOMElement.hasAttributeNS - Returns true if specified node exists
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  namespaceURI : string - the namespace URI of the required node
 * @param  localName    : string - the local name of the required node
 *
 * @return : boolean
 */
W3CDOMElement.prototype.hasAttributeNS = function W3CDOMElement_hasAttributeNS(namespaceURI, localName) {
  // delegate to W3CDOMNamedNodeMap._hasAttributeNS
  return this.attributes._hasAttributeNS(namespaceURI, localName);
}

/**
 * @method W3CDOMElement.toString - Serialize this Element and its children into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMElement.prototype.toString = function W3CDOMElement_toString() {
  var ret = "";

  // serialize namespace declarations
  var ns = this._namespaces.toString();
  if (ns.length > 0) ns = " "+ ns;

  // serialize Attribute declarations
  var attrs = this.attributes.toString();
  if (attrs.length > 0) attrs = " "+ attrs;

  // serialize this Element
  ret += "<" + this.nodeName + ns + attrs +">";
  ret += this.childNodes.toString();;
  ret += "</" + this.nodeName+">";

  return ret;
}

/**
 * @class  W3CDOMAttr - The Attr interface represents an attribute in an Element object
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMAttr = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMAttr");
  this.W3CDOMNode = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  this.name      = "";                           // the name of this attribute

  // If this attribute was explicitly given a value in the original document, this is true; otherwise, it is false.
  // Note that the implementation is in charge of this attribute, not the user.
  // If the user changes the value of the attribute (even if it ends up having the same value as the default value)
  // then the specified flag is automatically flipped to true
  // (I wish! You will need to use setValue to 'automatically' update specified)
  this.specified = false;

  this.value     = "";                           // the value of the attribute is returned as a string

  this.nodeType  = W3CDOMNode.ATTRIBUTE_NODE;

  this.ownerElement = null;                      // set when Attr is added to NamedNodeMap

  // disable childNodes
  this.childNodes = null;
  this.attributes = null;
};
W3CDOMAttr.prototype = new W3CDOMNode;

/**
 * @method W3CDOMAttr.getName - Java style gettor for .name
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMAttr.prototype.getName = function W3CDOMAttr_getName() {
  return this.nodeName;
};

/**
 * @method W3CDOMAttr.getSpecified - Java style gettor for .specified
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : boolean
 */
W3CDOMAttr.prototype.getSpecified = function W3CDOMAttr_getSpecified() {
  return this.specified;
};

/**
 * @method W3CDOMAttr.getValue - Java style gettor for .value
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMAttr.prototype.getValue = function W3CDOMAttr_getValue() {
  return this.nodeValue;
};

/**
 * @method W3CDOMAttr.setValue - Java style settor for .value
 *   alias for W3CDOMAttr.setNodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  value : string - the new attribute value
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Attribute is readonly.
 */
W3CDOMAttr.prototype.setValue = function W3CDOMAttr_setValue(value) {
  // throw Exception if Attribute is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // delegate to setNodeValue
  this.setNodeValue(value);
};

/**
 * @method W3CDOMAttr.setNodeValue - Java style settor for .nodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  value : string - the new attribute value
 */
W3CDOMAttr.prototype.setNodeValue = function W3CDOMAttr_setNodeValue(value) {
  this.nodeValue = new String(value);
  this.value     = this.nodeValue;
  this.specified = (this.value.length > 0);
};

/**
 * @method W3CDOMAttr.toString - Serialize this Attr into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMAttr.prototype.toString = function W3CDOMAttr_toString() {
  var ret = "";

  // serialize Attribute
  ret += this.nodeName +"=\""+ this.__escapeString(this.nodeValue) +"\"";

  return ret;
}

W3CDOMAttr.prototype.getOwnerElement = function() {

    return this.ownerElement;

}

/**
 * @class  W3CDOMNamespace - The Namespace interface represents an namespace in an Element object
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMNamespace = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMNamespace");
  this.W3CDOMNode = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  this.name      = "";                           // the name of this attribute

  // If this attribute was explicitly given a value in the original document, this is true; otherwise, it is false.
  // Note that the implementation is in charge of this attribute, not the user.
  // If the user changes the value of the attribute (even if it ends up having the same value as the default value)
  // then the specified flag is automatically flipped to true
  // (I wish! You will need to use _setValue to 'automatically' update specified)
  this.specified = false;

  this.value     = "";                           // the value of the attribute is returned as a string

  this.nodeType  = W3CDOMNode.NAMESPACE_NODE;
};
W3CDOMNamespace.prototype = new W3CDOMNode;

/**
 * @method W3CDOMNamespace.getValue - Java style gettor for .value
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMNamespace.prototype.getValue = function W3CDOMNamespace_getValue() {
  return this.nodeValue;
};

/**
 * @method W3CDOMNamespace.setValue - utility function to set value (rather than direct assignment to .value)
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  value : string - the new namespace value
 */
W3CDOMNamespace.prototype.setValue = function W3CDOMNamespace_setValue(value) {
  // assign values to properties (and aliases)
  this.nodeValue = new String(value);
  this.value     = this.nodeValue;
};

/**
 * @method W3CDOMNamespace.toString - Serialize this Attr into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMNamespace.prototype.toString = function W3CDOMNamespace_toString() {
  var ret = "";

  // serialize Namespace Declaration
  if (this.nodeName != "") {
    ret += this.nodeName +"=\""+ this.__escapeString(this.nodeValue) +"\"";
  }
  else {  // handle default namespace
    ret += "xmlns=\""+ this.__escapeString(this.nodeValue) +"\"";
  }

  return ret;
}

/**
 * @class  W3CDOMCharacterData - parent abstract class for W3CDOMText and W3CDOMComment
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMCharacterData = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMCharacterData");
  this.W3CDOMNode  = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  this.data   = "";
  this.length = 0;
};
W3CDOMCharacterData.prototype = new W3CDOMNode;

/**
 * @method W3CDOMCharacterData.getData - Java style gettor for .data
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMCharacterData.prototype.getData = function W3CDOMCharacterData_getData() {
  return this.nodeValue;
};

/**
 * @method W3CDOMCharacterData.setData - Java style settor for .data
 *  alias for W3CDOMCharacterData.setNodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - the character data
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Attribute is readonly.
 */
W3CDOMCharacterData.prototype.setData = function W3CDOMCharacterData_setData(data) {
  // delegate to setNodeValue
  this.setNodeValue(data);
};

/**
 * @method W3CDOMCharacterData.setNodeValue - Java style settor for .nodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - the node value
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Attribute is readonly.
 */
W3CDOMCharacterData.prototype.setNodeValue = function W3CDOMCharacterData_setNodeValue(data) {
  // throw Exception if Attribute is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // assign values to properties (and aliases)
  this.nodeValue = new String(data);
  this.data   = this.nodeValue;

  // update length
  this.length = this.nodeValue.length;
};

/**
 * @method W3CDOMCharacterData.getLength - Java style gettor for .length
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMCharacterData.prototype.getLength = function W3CDOMCharacterData_getLength() {
  return this.nodeValue.length;
};

/**
 * @method W3CDOMCharacterData.substringData - Extracts a range of data from the node
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int - Start offset of substring to extract
 * @param  count  : int - The number of characters to extract
 *
 * @throws : W3CDOMException - INDEX_SIZE_ERR: Raised if specified offset is negative or greater than the number of 16-bit units in data,
 *
 * @return : string - The specified substring.
 *   If the sum of offset and count exceeds the length, then all characters to the end of the data are returned.
 */
W3CDOMCharacterData.prototype.substringData = function W3CDOMCharacterData_substringData(offset, count) {
  var ret = null;

  if (this.data) {
    // throw Exception if offset is negative or greater than the data length,
    // or the count is negative
    if (this.ownerDocument.implementation.errorChecking && ((offset < 0) || (offset > this.data.length) || (count < 0))) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }

    // if count is not specified
    if (!count) {
      ret = this.data.substring(offset); // default to 'end of string'
    }
    else {
      ret = this.data.substring(offset, offset + count);
    }
  }

  return ret;
};

/**
 * @method W3CDOMCharacterData.appendData - Append the string to the end of the character data of the node.
 *   Upon success, data provides access to the concatenation of data and the W3CDOMString specified.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  arg : string - The string to append
 *
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this CharacterData is readonly.
 */
W3CDOMCharacterData.prototype.appendData    = function W3CDOMCharacterData_appendData(arg) {
  // throw Exception if W3CDOMCharacterData is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // append data
  this.setData(""+ this.data + arg);
};

/**
 * @method W3CDOMCharacterData.insertData - Insert a string at the specified character offset.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int    - The character offset at which to insert
 * @param  arg    : string - The string to insert
 *
 * @throws : W3CDOMException - INDEX_SIZE_ERR: Raised if specified offset is negative or greater than the number of 16-bit units in data,
 *   or if the specified count is negative.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this CharacterData is readonly.
 */
W3CDOMCharacterData.prototype.insertData    = function W3CDOMCharacterData_insertData(offset, arg) {
  // throw Exception if W3CDOMCharacterData is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  if (this.data) {
    // throw Exception if offset is negative or greater than the data length,
    if (this.ownerDocument.implementation.errorChecking && ((offset < 0) || (offset >  this.data.length))) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }

    // insert data
    this.setData(this.data.substring(0, offset).concat(arg, this.data.substring(offset)));
  }
  else {
    // throw Exception if offset is negative or greater than the data length,
    if (this.ownerDocument.implementation.errorChecking && (offset != 0)) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }

    // set data
    this.setData(arg);
  }
};

/**
 * @method W3CDOMCharacterData.deleteData - Remove a range of characters from the node.
 *   Upon success, data and length reflect the change
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int - The offset from which to remove characters
 * @param  count  : int - The number of characters to delete.
 *   If the sum of offset and count exceeds length then all characters from offset to the end of the data are deleted
 *
 * @throws : W3CDOMException - INDEX_SIZE_ERR: Raised if specified offset is negative or greater than the number of 16-bit units in data,
 *   or if the specified count is negative.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this CharacterData is readonly.
 */
W3CDOMCharacterData.prototype.deleteData    = function W3CDOMCharacterData_deleteData(offset, count) {
  // throw Exception if W3CDOMCharacterData is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  if (this.data) {
    // throw Exception if offset is negative or greater than the data length,
    if (this.ownerDocument.implementation.errorChecking && ((offset < 0) || (offset >  this.data.length) || (count < 0))) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }

    // delete data
    if(!count || (offset + count) > this.data.length) {
      this.setData(this.data.substring(0, offset));
    }
    else {
      this.setData(this.data.substring(0, offset).concat(this.data.substring(offset + count)));
    }
  }
};

/**
 * @method W3CDOMCharacterData.replaceData - Replace the characters starting at the specified character offset with the specified string
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int    - The offset from which to start replacing
 * @param  count  : int    - The number of characters to replace.
 *   If the sum of offset and count exceeds length, then all characters to the end of the data are replaced
 * @param  arg    : string - The string with which the range must be replaced
 *
 * @throws : W3CDOMException - INDEX_SIZE_ERR: Raised if specified offset is negative or greater than the number of 16-bit units in data,
 *   or if the specified count is negative.
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this CharacterData is readonly.
 */
W3CDOMCharacterData.prototype.replaceData   = function W3CDOMCharacterData_replaceData(offset, count, arg) {
  // throw Exception if W3CDOMCharacterData is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  if (this.data) {
    // throw Exception if offset is negative or greater than the data length,
    if (this.ownerDocument.implementation.errorChecking && ((offset < 0) || (offset >  this.data.length) || (count < 0))) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }

    // replace data
    this.setData(this.data.substring(0, offset).concat(arg, this.data.substring(offset + count)));
  }
  else {
    // set data
    this.setData(arg);
  }
};

/**
 * @class  W3CDOMText - The Text interface represents the textual content (termed character data in XML) of an Element or Attr.
 *   If there is no markup inside an element's content, the text is contained in a single object implementing the Text interface
 *   that is the only child of the element. If there is markup, it is parsed into a list of elements and Text nodes that form the
 *   list of children of the element.
 *
 * @extends W3CDOMCharacterData
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMText = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMText");
  this.W3CDOMCharacterData  = W3CDOMCharacterData;
  this.W3CDOMCharacterData(ownerDocument);

  this.nodeName  = "#text";
  this.nodeType  = W3CDOMNode.TEXT_NODE;
};
W3CDOMText.prototype = new W3CDOMCharacterData;

/**
 * @method W3CDOMText.splitText - Breaks this Text node into two Text nodes at the specified offset,
 *   keeping both in the tree as siblings. This node then only contains all the content up to the offset point.
 *   And a new Text node, which is inserted as the next sibling of this node, contains all the content at and after the offset point.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int - The offset at which to split, starting from 0.
 *
 * @throws : W3CDOMException - INDEX_SIZE_ERR: Raised if specified offset is negative or greater than the number of 16-bit units in data,
 * @throws : W3CDOMException - NO_MODIFICATION_ALLOWED_ERR: Raised if this Text is readonly.
 *
 * @return : W3CDOMText - The new Text node
 */
W3CDOMText.prototype.splitText = function W3CDOMText_splitText(offset) {
  var data, inode;

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if Node is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if offset is negative or greater than the data length,
    if ((offset < 0) || (offset > this.data.length)) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }
  }

  if (this.parentNode) {
    // get remaining string (after offset)
    data  = this.substringData(offset);

    // create new TextNode with remaining string
    inode = this.ownerDocument.createTextNode(data);

    // attach new TextNode
    if (this.nextSibling) {
      this.parentNode.insertBefore(inode, this.nextSibling);
    }
    else {
      this.parentNode.appendChild(inode);
    }

    // remove remaining string from original TextNode
    this.deleteData(offset);
  }

  return inode;
};

/**
 * @method W3CDOMText.toString - Serialize this Text into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMText.prototype.toString = function W3CDOMText_toString() {
  return this.__escapeString(""+ this.nodeValue);
}

/**
 * @class  W3CDOMCDATASection - CDATA sections are used to escape blocks of text containing characters that would otherwise be regarded as markup.
 *   The only delimiter that is recognized in a CDATA section is the "\]\]\>" string that ends the CDATA section
 *
 * @extends W3CDOMCharacterData
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMCDATASection = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMCDATASection");
  this.W3CDOMCharacterData  = W3CDOMCharacterData;
  this.W3CDOMCharacterData(ownerDocument);

  this.nodeName  = "#cdata-section";
  this.nodeType  = W3CDOMNode.CDATA_SECTION_NODE;
};
W3CDOMCDATASection.prototype = new W3CDOMCharacterData;

/**
 * @method W3CDOMCDATASection.splitText - Breaks this CDATASection node into two CDATASection nodes at the specified offset,
 *   keeping both in the tree as siblings. This node then only contains all the content up to the offset point.
 *   And a new CDATASection node, which is inserted as the next sibling of this node, contains all the content at and after the offset point.
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  offset : int - The offset at which to split, starting from 0.
 *
 * @return : W3CDOMCDATASection - The new CDATASection node
 */
W3CDOMCDATASection.prototype.splitText = function W3CDOMCDATASection_splitText(offset) {
  var data, inode;

  // test for exceptions
  if (this.ownerDocument.implementation.errorChecking) {
    // throw Exception if Node is readonly
    if (this._readonly) {
      throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
    }

    // throw Exception if offset is negative or greater than the data length,
    if ((offset < 0) || (offset > this.data.length)) {
      throw(new W3CDOMException(W3CDOMException.INDEX_SIZE_ERR));
    }
  }

  if(this.parentNode) {
    // get remaining string (after offset)
    data  = this.substringData(offset);

    // create new CDATANode with remaining string
    inode = this.ownerDocument.createCDATASection(data);

    // attach new CDATANode
    if (this.nextSibling) {
      this.parentNode.insertBefore(inode, this.nextSibling);
    }
    else {
      this.parentNode.appendChild(inode);
    }

     // remove remaining string from original CDATANode
    this.deleteData(offset);
  }

  return inode;
};

/**
 * @method W3CDOMCDATASection.toString - Serialize this CDATASection into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMCDATASection.prototype.toString = function W3CDOMCDATASection_toString() {
  var ret = "";
  //do NOT unescape the nodeValue string in CDATA sections!
  ret += "<![CDATA[" + this.nodeValue + "\]\]\>";

  return ret;
}

/**
 * @class  W3CDOMComment - This represents the content of a comment, i.e., all the characters between the starting '<!--' and ending '-->'
 *
 * @extends W3CDOMCharacterData
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMComment = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMComment");
  this.W3CDOMCharacterData  = W3CDOMCharacterData;
  this.W3CDOMCharacterData(ownerDocument);

  this.nodeName  = "#comment";
  this.nodeType  = W3CDOMNode.COMMENT_NODE;
};
W3CDOMComment.prototype = new W3CDOMCharacterData;

/**
 * @method W3CDOMComment.toString - Serialize this Comment into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMComment.prototype.toString = function W3CDOMComment_toString() {
  var ret = "";

  ret += "<!--" + this.nodeValue + "-->";

  return ret;
}

/**
 * @class  W3CDOMProcessingInstruction - The ProcessingInstruction interface represents a "processing instruction",
 *   used in XML as a way to keep processor-specific information in the text of the document
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMProcessingInstruction = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMProcessingInstruction");
  this.W3CDOMNode  = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  // The target of this processing instruction.
  // XML defines this as being the first token following the markup that begins the processing instruction.
  this.target = "";

  // The content of this processing instruction.
  // This is from the first non white space character after the target to the character immediately preceding the ?>
  this.data   = "";

  this.nodeType  = W3CDOMNode.PROCESSING_INSTRUCTION_NODE;
};
W3CDOMProcessingInstruction.prototype = new W3CDOMNode;

/**
 * @method W3CDOMProcessingInstruction.getTarget - Java style gettor for .target
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMProcessingInstruction.prototype.getTarget = function W3CDOMProcessingInstruction_getTarget() {
  return this.nodeName;
};

/**
 * @method W3CDOMProcessingInstruction.getData - Java style gettor for .data
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @return : string
 */
W3CDOMProcessingInstruction.prototype.getData = function W3CDOMProcessingInstruction_getData() {
  return this.nodeValue;
};

/**
 * @method W3CDOMProcessingInstruction.setData - Java style settor for .data
 *   alias for W3CDOMProcessingInstruction.setNodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - The new data of this processing instruction.
 */
W3CDOMProcessingInstruction.prototype.setData = function W3CDOMProcessingInstruction_setData(data) {
  // delegate to setNodeValue
  this.setNodeValue(data);
};

/**
 * @method W3CDOMProcessingInstruction.setNodeValue - Java style settor for .nodeValue
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  data : string - The new data of this processing instruction.
 */
W3CDOMProcessingInstruction.prototype.setNodeValue = function W3CDOMProcessingInstruction_setNodeValue(data) {
  // throw Exception if W3CDOMNode is readonly
  if (this.ownerDocument.implementation.errorChecking && this._readonly) {
    throw(new W3CDOMException(W3CDOMException.NO_MODIFICATION_ALLOWED_ERR));
  }

  // assign values to properties (and aliases)
  this.nodeValue = new String(data);
  this.data = this.nodeValue;
};

/**
 * @method W3CDOMProcessingInstruction.toString - Serialize this ProcessingInstruction into an XML string
 *
 * @author Jon van Noort (jon@webarcana.com.au) and David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMProcessingInstruction.prototype.toString = function W3CDOMProcessingInstruction_toString() {
  var ret = "";

  ret += "<?" + this.nodeName +" "+ this.nodeValue + " ?>";

  return ret;
}

/**
 * @class  W3CDOMDocumentFragment - DocumentFragment is a "lightweight" or "minimal" Document object.
 *
 * @extends W3CDOMNode
 *
 * @author Jon van Noort (jon@webarcana.com.au)
 *
 * @param  ownerDocument : W3CDOMDocument - The Document object associated with this node.
 */
W3CDOMDocumentFragment = function(ownerDocument) {
  this._class = addClass(this._class, "W3CDOMDocumentFragment");
  this.W3CDOMNode = W3CDOMNode;
  this.W3CDOMNode(ownerDocument);

  this.nodeName  = "#document-fragment";
  this.nodeType = W3CDOMNode.DOCUMENT_FRAGMENT_NODE;
};
W3CDOMDocumentFragment.prototype = new W3CDOMNode;

/**
 * @method W3CDOMDocumentFragment.toString - Serialize this DocumentFragment into an XML string
 *
 * @author David Joham (djoham@yahoo.com)
 *
 * @return : string
 */
W3CDOMDocumentFragment.prototype.toString = function W3CDOMDocumentFragment_toString() {
  var xml = "";
  var intCount = this.getChildNodes().getLength();

  // create string concatenating the serialized ChildNodes
  for (intLoop = 0; intLoop < intCount; intLoop++) {
    xml += this.getChildNodes().item(intLoop).toString();
  }

  return xml;
}

///////////////////////
//  NOT IMPLEMENTED  //
///////////////////////
W3CDOMDocumentType    = function() { alert("W3CDOMDocumentType.constructor(): Not Implemented"   ); };
W3CDOMEntity          = function() { alert("W3CDOMEntity.constructor(): Not Implemented"         ); };
W3CDOMEntityReference = function() { alert("W3CDOMEntityReference.constructor(): Not Implemented"); };
W3CDOMNotation        = function() { alert("W3CDOMNotation.constructor(): Not Implemented"       ); };


Strings = new Object()
Strings.WHITESPACE = " \t\n\r";
Strings.QUOTES = "\"'";

Strings.isEmpty = function Strings_isEmpty(strD) {
    return (strD == null) || (strD.length == 0);
};
Strings.indexOfNonWhitespace = function Strings_indexOfNonWhitespace(strD, iB, iE) {
  if(Strings.isEmpty(strD)) return -1;
  iB = iB || 0;
  iE = iE || strD.length;

  for(var i = iB; i < iE; i++)
    if(Strings.WHITESPACE.indexOf(strD.charAt(i)) == -1) {
      return i;
    }
  return -1;
};
Strings.lastIndexOfNonWhitespace = function Strings_lastIndexOfNonWhitespace(strD, iB, iE) {
  if(Strings.isEmpty(strD)) return -1;
  iB = iB || 0;
  iE = iE || strD.length;

  for(var i = iE - 1; i >= iB; i--)
    if(Strings.WHITESPACE.indexOf(strD.charAt(i)) == -1)
      return i;
  return -1;
};
Strings.indexOfWhitespace = function Strings_indexOfWhitespace(strD, iB, iE) {
  if(Strings.isEmpty(strD)) return -1;
  iB = iB || 0;
  iE = iE || strD.length;

  for(var i = iB; i < iE; i++)
    if(Strings.WHITESPACE.indexOf(strD.charAt(i)) != -1)
      return i;
  return -1;
};
Strings.replace = function Strings_replace(strD, iB, iE, strF, strR) {
  if(Strings.isEmpty(strD)) return "";
  iB = iB || 0;
  iE = iE || strD.length;

  return strD.substring(iB, iE).split(strF).join(strR);
};
Strings.getLineNumber = function Strings_getLineNumber(strD, iP) {
  if(Strings.isEmpty(strD)) return -1;
  iP = iP || strD.length;

  return strD.substring(0, iP).split("\n").length
};
Strings.getColumnNumber = function Strings_getColumnNumber(strD, iP) {
  if(Strings.isEmpty(strD)) return -1;
  iP = iP || strD.length;

  var arrD = strD.substring(0, iP).split("\n");
  var strLine = arrD[arrD.length - 1];
  arrD.length--;
  var iLinePos = arrD.join("\n").length;

  return iP - iLinePos;
};


StringBuffer = function() {this._a=new Array();};
StringBuffer.prototype.append = function StringBuffer_append(d){this._a[this._a.length]=d;};
StringBuffer.prototype.toString = function StringBuffer_toString(){return this._a.join("");};
