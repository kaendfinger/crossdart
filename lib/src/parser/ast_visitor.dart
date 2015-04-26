library crossdart.parser.ast_visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';

import 'package:crossdart/src/location.dart';
import 'package:crossdart/src/environment.dart';
import 'package:crossdart/src/parsed_data.dart';
import 'package:crossdart/src/entity.dart' as e;
import 'package:logging/logging.dart' as logging;

var _logger = new logging.Logger("parser");

class ASTVisitor extends GeneralizingAstVisitor {
  static const KEYWORD = "keyword";
  static const DECLARATION = "declaration";
  static const ANNOTATION = "annotation";
  static const STRING = "string";

  Environment _environment;
  String _absolutePath;

  ASTVisitor(this._environment, this._absolutePath, this._parsedData);

  ParsedData _parsedData;
  ParsedData get parsedData => _parsedData;

  visitNode(AstNode node) {
    super.visitNode(node);
    //print("Node ${node}, type: ${node.runtimeType}, beginToken: ${node.beginToken}, endToken: ${node.endToken}");
  }

  visitDirective(Directive node) {
    super.visitDirective(node);
    _addToken(KEYWORD, node.keyword);
  }

  visitComment(Comment node) {
    super.visitComment(node);
    _addToken(node.runtimeType.toString().toLowerCase(), node.beginToken, node.endToken);
  }

  visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);
    if (node.abstractKeyword != null) {
      _addToken(KEYWORD, node.abstractKeyword);
    }
    _addToken(KEYWORD, node.classKeyword);
  }

  visitExtendsClause(ExtendsClause node) {
    super.visitExtendsClause(node);
    _addToken(KEYWORD, node.keyword);
  }

  visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    [node.externalKeyword, node.modifierKeyword, node.operatorKeyword, node.propertyKeyword].forEach((keyword) {
      if (keyword != null) {
        _addToken(KEYWORD, keyword);
      }
    });

    _addToken(DECLARATION, node.name.token);
  }

  visitPartOfDirecive(PartOfDirective node) {
    super.visitPartOfDirective(node);
    _addToken(KEYWORD, node.partToken, node.ofToken);
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    [node.externalKeyword, node.constKeyword, node.factoryKeyword].forEach((keyword) {
      if (keyword != null) {
        _addToken(KEYWORD, keyword);
      }
    });
    if (node.name != null) {
      _addToken(DECLARATION, node.name.token);
    }
  }

  visitSuperExpression(SuperExpression node) {
    super.visitSuperExpression(node);
    _addToken(KEYWORD, node.beginToken);
  }

  visitReturnStatement(ReturnStatement node) {
    super.visitReturnStatement(node);
    _addToken(KEYWORD, node.keyword);
  }

  visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    _addToken(KEYWORD, node.keyword);
  }

  visitAnnotation(Annotation node) {
    super.visitAnnotation(node);
    _addToken(ANNOTATION, node.beginToken, node.endToken);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    super.visitSimpleStringLiteral(node);
    _addToken(STRING, node.literal);
    try {
      var parent = node.parent;
      if (parent is PartDirective) {
        var reference = new e.Reference(new Location.fromEnvironment(_environment, _absolutePath), name: node.toString(), offset: node.offset, end: node.end);
        var declaration = new e.Import(new Location.fromEnvironment(_environment, parent.element.source.fullName));
        _addReferenceAndDeclaration(reference, declaration);
      } else if (parent is ImportDirective) {// && parent.element != null) {
        var reference = new e.Reference(new Location.fromEnvironment(_environment, _absolutePath), name: node.toString(), offset: node.offset, end: node.end);
        var declaration = new e.Import(new Location.fromEnvironment(_environment, parent.element.importedLibrary.definingCompilationUnit.source.fullName));
        _addReferenceAndDeclaration(reference, declaration);
      }
    } catch(error, stackTrace) {
      _logger.severe("Error parsing simple string literal $node", error, stackTrace);
    }
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    super.visitSimpleIdentifier(node);
    if (node.parent != null && node.parent.parent is PartOfDirective) {
      try {
        PartOfDirective partOfNode = node.parent.parent;
        var reference = new e.Reference(new Location.fromEnvironment(_environment, _absolutePath), name: node.toString(), offset: node.offset, end: node.end);
        var declaration = new e.Import(new Location.fromEnvironment(_environment, partOfNode.element.source.fullName));
        _addReferenceAndDeclaration(reference, declaration);
      } catch(error, stackTrace) {
        _logger.severe("Error parsing 'part of' node $node", error, stackTrace);
      }
    } else {
      try {
        Element element = node.bestElement;
        if (element != null && element.library != null && element.node is Declaration && !node.inDeclarationContext()) {
          var reference = new e.Reference(new Location.fromEnvironment(_environment, _absolutePath), name: node.bestElement.displayName, offset: node.offset, end: node.end);
          var declarationElement = (element.node as Declaration).element;
          var declaration = new e.Declaration(new Location.fromEnvironment(_environment, declarationElement.source.fullName),
              name: declarationElement.displayName,
              offset: element.node.offset,
              end: element.node.end);

          _addReferenceAndDeclaration(reference, declaration);
        }
      } catch(error, stackTrace) {
        _logger.severe("Error parsing a reference/declaration $node", error, stackTrace);
      }
    }
  }

  void _addReferenceAndDeclaration(e.Reference reference, e.Declaration declaration) {
    if (parsedData.files[reference.location.file] == null) {
      parsedData.files[reference.location.file] = new Set();
    }
    parsedData.files[reference.location.file].add(reference);

    if (parsedData.files[declaration.location.file] == null) {
      parsedData.files[declaration.location.file] = new Set();
    }
    parsedData.files[declaration.location.file].add(declaration);

    if (parsedData.declarations[declaration] == null) {
      parsedData.declarations[declaration] = new Set();
    }
    parsedData.declarations[declaration].add(reference);

    parsedData.references[reference] = declaration;
  }

  void _addToken(String name, Token beginToken, [Token endToken]) {
    var offset = beginToken.offset;
    var end = endToken == null ? beginToken.end : endToken.end;
    var newToken = new e.Token(new Location.fromEnvironment(_environment, _absolutePath), name: name, offset: offset, end: end);

    parsedData.tokens.add(newToken);
    if (parsedData.files[newToken.location.file] == null) {
      parsedData.files[newToken.location.file] = new Set();
    }
    parsedData.files[newToken.location.file].add(newToken);
  }
}