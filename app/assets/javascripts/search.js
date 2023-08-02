/* eslint-disable require-jsdoc */

// eslint-disable-next-line no-unused-vars
const SearchService = (function() {
  let intervalsCount = 0;

  return {
    init: function(supportedLanguages) {
      const elems = document.querySelectorAll('select');
      M.FormSelect.init(elems, {});

      languages = supportedLanguages;
      this.selectUserLanguage(document.getElementById('select-translate-to'));
    },

    selectUserLanguage: function(sel) {
      if (!sel) return;

      languageSelection(sel);
      this.translate();
    },

    translate: function() {
      const textDetected = document.getElementById('text-detected').innerText;
      const from = document.getElementById('select-translate-from').value;
      const to = document.getElementById('select-translate-to').value;

      if (translationIssue(textDetected, from, to)) return;

      const url = '/translate';
      const params = translationParams(textDetected, from, to);
      makeCall(url, 'POST', params, setTranslatedText);
    },

    filterOrSort: function(searchId, verified, full, partial) {
      const filterBy = document.getElementById('select-filter-by').value;
      const sortOrder = document
          .querySelector('input[type=radio].sort-order:checked + span')
          .innerText.toLowerCase();
      const matchTypes = ['full_matches', 'partial_matches', 'verified'];
      const matches = [full, partial, verified];

      this.fade();
      
      matchTypes.forEach((matchType, idx) => {
        makeCall(
            '/searches/' + searchId + '/sort_and_filter_results', 'POST',
            searchParams(matchType, matches[idx], sortOrder, filterBy),
            refreshMatches,
            matchType,
        );
      });
    },

    fade: function() {
      notify = document.getElementById('notify-results');
      notify.classList.add('fade');
      var newone = notify.cloneNode(true);
      notify.parentNode.replaceChild(newone, notify);
    },

    toggleLongText: function(ev) {
      ev = ev || window.event;
      const par = ev.target || ev.srcElement;
      ev.preventDefault();
      ev.stopPropagation();

      const longTextClass = 'long-text';
      if (par.classList.contains(longTextClass)) {
        par.classList.remove(longTextClass);
      } else {
        par.classList.add(longTextClass);
      }
    },

    triggerFullResults: function(searchId, btn) {
      btn.style.display = 'none';
      intervalsCount = 0;
      const overlay = document.getElementById('overlay-upload-image');
      const overlayText = document.getElementById('overlay-text');

      overlay.classList.add('visible');
      overlayText.innerText = 'Searching ...';
      let interval = null;
      const self = this;
      makeCall(`/searches/${searchId}/trigger_full_analysis`, 'POST',
          JSON.stringify( {} ), function() {
            interval = setInterval(function() {
              if (intervalsCount >= 3) {
                handleInterval(interval, overlay, overlayText);
              } else {
                self.fullResults(searchId);
              }
            }, 5000);
          });

      // delete interval if response is not delivered in 40secs
      setTimeout(function() {
        handleInterval(interval, overlay, overlayText);
        if (intervalsCount === 0) {
          btn.style.display = 'block';
        }
      }, 40000);
    },

    fullResults: function(searchId) {
      const self = this;
      const matchTypes = ['full_matches', 'partial_matches', 'verified'];
      matchTypes.forEach((matchType) => {
        makeCall('/searches/' + searchId + '/full_results.html', 'POST',
            JSON.stringify( {search: {'section': matchType}} ),
            function(res) {
              if (res) {
                intervalsCount++;
                refreshMatches(res, matchType);
                self.fullResultsJson(searchId);
              }
            },
        );
      });
    },

    fullResultsJson(searchId) {
      makeCall('/searches/' + searchId + '/full_results.json', 'POST',
          JSON.stringify( { }), function(res) {
            const jsonResults = JSON.parse(res).results;
            fullMatches = jsonResults.full_matches;
            partialMatches = jsonResults.partial_matches;
            verifiedMatches = jsonResults.verified;
          },
      );
    },
  };
})();

function makeCall(url, method, params, ...args) {
  const xmlhttp = new XMLHttpRequest();
  const callback = args[0];
  const calbackArgs = args.slice(1);

  xmlhttp.onreadystatechange = function() {
    if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
      callback(xmlhttp.responseText, ...calbackArgs);
    }
  };
  xmlhttp.open(method, url, true);
  xmlhttp.setRequestHeader('Content-Type', 'application/json');
  xmlhttp.send(params);
}

function refreshMatches(response, matchType) {
  matchType = matchType.replace('_', '-');
  document.getElementById(matchType).innerHTML = response;
  ImageLazyLoader.init('.card-image img');
}

const setUserLanguage = function() {
  if (navigator.languages) {
    return navigator.languages[0];
  } else {
    return (navigator.language || navigator.userLanguage);
  }
};

const cleanedText = function(text) {
  text = text.replace(/&quot;/g, '"');
  text = text.replace(/&#34;/g, '"');
  return text.replace(/&#39;/g, '"');
};

const setContainer = function(response) {
  if (response.error === true) {
    return 'translated-text-container visible error';
  } else {
    return 'translated-text-container visible';
  }
};

function searchParams(matchType, matches, sortOrder, filterBy) {
  return JSON.stringify({
    search: {
      'section': matchType, 'results': matches, 'sort_order': sortOrder,
      'filter_by': filterBy,
    },
  });
}

function handleInterval(interval, overlay, overlayText) {
  clearInterval(interval);
  overlay.classList.remove('visible');
  overlayText.innerText = 'Upload Image';
}

function languageSelection(sel) {
  const userLanguage = setUserLanguage();
  const languages = [];
  let languageToSelect = 'en';
  const regex = new RegExp('^' + userLanguage, 'ig');
  for (let i = 0; i < languages.length; i++) {
    if (regex.test(languages[i]['code'])) {
      languageToSelect = languages[i]['code'];
      break;
    }
  }
  sel.value = languageToSelect;
  M.FormSelect.init(sel, {});
}

function translationIssue(textDetected, from, to) {
  return (!textDetected.length || !from.length || !to.length || from === to);
}

function translationParams(textDetected, from, to) {
  return JSON.stringify({
    'translate_text': textDetected,
    'translate_from': from,
    'translate_to': to,
  });
}

function setTranslatedText(response) {
  const jsonResponse = JSON.parse(response);
  if (jsonResponse.translated_text.length) {
    const translatedText = cleanedText(jsonResponse.translated_text);

    const containerClass = setContainer(jsonResponse);
    const container = document.getElementById('translated-text-container');
    container.className = containerClass;
    document.getElementById('translated-text').innerText = translatedText;
  }
}
