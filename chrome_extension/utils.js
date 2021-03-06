function groupBy(coll, context) {
  return coll.reduce(function (memo, item) {
    var value = context(item);
    if (memo[value] === undefined) {
      memo[value] = [];
    }
    memo[value].push(item);
    return memo;
  }, {});
}

function getRealOffset(content, offset) {
  var regexps = [[/(<[^>]*>)/g, 0], [/(&\w+;)/g, 1]];
  var positions = regexps.reduce(function (memo, item) {
    var regexp = item[0];
    var regexpLength = item[1];
    var matches = content.match(regexp);
    var matchPos = 0;
    for (var matchIndex in (matches || [])) {
      if (matches.hasOwnProperty(matchIndex)) {
        var match = matches[matchIndex];
        var matchOffset = content.substr(matchPos).search(regexp);
        memo.push([matchPos + matchOffset, matchPos + matchOffset + match.length, regexpLength]);
        matchPos += matchOffset + match.length;
      }
    }
    return memo;
  }, []).sort(function (a, b) { return a[0] - b[0]; });
  var realOffset = offset;
  while (positions.length > 0 && realOffset > positions[0][0]) {
    var position = positions.shift();
    var length = position[1] - position[0] - position[2];
    realOffset += length;
  }
  return realOffset;
}

function groupEntitiesByLinesAndTypes(allEntities) {
  var result = {};
  for (var type in allEntities) {
    var entities = allEntities[type];
    for (var i in entities) {
      var entity = JSON.parse(JSON.stringify(entities[i]));
      entity.type = type;
      var line = parseInt(entity.line, 10);
      result[line] = result[line] || [];
      result[line].push(entity);
    }
  }
  return result;
}

function applyEntities(github, ref, content, entities, hrefCallback) {
  if (content.indexOf("crossdart-link") === -1) {
    var newLineContent = "";
    var lastStop = 0;
    for (var index in entities) {
      var entity = entities[index];
      var realOffset = getRealOffset(content, entity.offset);
      newLineContent += content.substr(lastStop, realOffset - lastStop);
      if (entity.type == "references") {
        var href = hrefCallback(entity);
        var isInternal = href.match(/^#/) || href.match(new RegExp(location.pathname));
        var cssClass = "crossdart-link" + (!isInternal ? ' crossdart-link__external' : '');
        newLineContent += "<a href='" + href + "' class='" + cssClass + "'>";
      } else if (entity.type == "declarations") {
        var references = JSON.stringify(entity.references);
        newLineContent += "<span class='crossdart-declaration' data-references='" + references + "' data-ref='" + ref + "'>";
      }
      var end = entity.offset + entity.length;
      var realEnd = getRealOffset(content, end);
      newLineContent += content.substr(realOffset, realEnd - realOffset);
      if (entity.type == "references") {
        newLineContent += "</a>";
      } else if (entity.type == "declarations") {
        newLineContent += "</span>";
      }
      lastStop = realEnd;
    }
    var lastEntity = entities[entities.length - 1];
    var lastEnd = lastEntity.offset + lastEntity.length;
    var lastRealEnd = getRealOffset(content, lastEnd);
    newLineContent += content.substr(lastRealEnd);
    return newLineContent;
  } else {
    return content;
  }
}
