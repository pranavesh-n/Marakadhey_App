import { Opportunity } from '../types/opportunity';

function formatTime12Hour(isoDateString: string): string {
  const d = new Date(isoDateString);
  if (isNaN(d.getTime())) return '';
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });
}

function buildEventDescription(opp: Opportunity): string {
  let cleanTitle = opp.title || '';
  if (cleanTitle.length > 120) {
    cleanTitle = cleanTitle.substring(0, 120) + '...';
  }

  let cleanNote = opp.notes ? opp.notes.trim() : (opp.description ? opp.description.trim() : '');
  if (cleanNote.length > 500) {
    cleanNote = cleanNote.substring(0, 500) + '... (Truncated)';
  }

  const capitalizedPriority = opp.priority
    ? opp.priority.charAt(0).toUpperCase() + opp.priority.slice(1).toLowerCase()
    : 'Medium';

  const dateStr = new Date(opp.deadline).toLocaleDateString();
  const timeStr = formatTime12Hour(opp.deadline);

  let description = 'Saved via Marakadhey Mobile App\n\n';
  description += `Title:\n${cleanTitle}\n\n`;
  description += `Scheduled Time:\n${dateStr} at ${timeStr}\n\n`;
  description += `Category:\n${opp.category}\n\n`;
  description += `Priority:\n${capitalizedPriority}\n\n`;
  if (opp.websiteUrl) {
    description += `URL:\n${opp.websiteUrl}\n\n`;
  }
  if (cleanNote) {
    description += `Notes:\n${cleanNote}`;
  }
  return description;
}

export function generateGoogleCalendarLink(opp: Opportunity): string {
  const startDt = new Date(opp.deadline);
  if (isNaN(startDt.getTime())) return '';

  const endDt = new Date(startDt.getTime() + 15 * 60 * 1000);

  const formatToGCalUTCString = (date: Date) => {
    const y = date.getUTCFullYear();
    const m = String(date.getUTCMonth() + 1).padStart(2, '0');
    const d = String(date.getUTCDate()).padStart(2, '0');
    const hh = String(date.getUTCHours()).padStart(2, '0');
    const mm = String(date.getUTCMinutes()).padStart(2, '0');
    const ss = String(date.getUTCSeconds()).padStart(2, '0');
    return `${y}${m}${d}T${hh}${mm}${ss}Z`;
  };

  const datesParam = `${formatToGCalUTCString(startDt)}/${formatToGCalUTCString(endDt)}`;
  const baseUrl = 'https://www.google.com/calendar/render';
  const params = new URLSearchParams({
    action: 'TEMPLATE',
    text: opp.title || '',
    dates: datesParam,
    details: buildEventDescription(opp),
    location: opp.websiteUrl || '',
  });

  if (opp.isRecurring && opp.recurrenceRule) {
    let rrule = '';
    switch (opp.recurrenceRule) {
      case 'DAILY':
        rrule = 'RRULE:FREQ=DAILY';
        break;
      case 'WEEKLY':
        rrule = 'RRULE:FREQ=WEEKLY';
        break;
      case 'MONTHLY':
        rrule = 'RRULE:FREQ=MONTHLY';
        break;
    }
    if (rrule) {
      params.set('recur', rrule);
    }
  }

  return `${baseUrl}?${params.toString()}`;
}

export function generateOutlookCalendarLink(opp: Opportunity): string {
  const startDt = new Date(opp.deadline);
  if (isNaN(startDt.getTime())) return '';

  const endDt = new Date(startDt.getTime() + 15 * 60 * 1000);
  const baseUrl = 'https://outlook.live.com/calendar/0/deeplink/compose';
  const params = new URLSearchParams({
    path: '/calendar/action/compose',
    rru: 'addevent',
    subject: opp.title || '',
    startdt: startDt.toISOString(),
    enddt: endDt.toISOString(),
    body: buildEventDescription(opp),
    location: opp.websiteUrl || '',
  });

  return `${baseUrl}?${params.toString()}`;
}

export function generateYahooCalendarLink(opp: Opportunity): string {
  const startDt = new Date(opp.deadline);
  if (isNaN(startDt.getTime())) return '';

  const formatYahooISO = (d: Date) => {
    return d.toISOString().replace(/-|:|\.\d+/g, '');
  };

  const endDt = new Date(startDt.getTime() + 15 * 60 * 1000);
  const baseUrl = 'https://calendar.yahoo.com/';
  const params = new URLSearchParams({
    v: '60',
    TITLE: opp.title || '',
    ST: formatYahooISO(startDt),
    ET: formatYahooISO(endDt),
    DESC: buildEventDescription(opp),
    in_loc: opp.websiteUrl || '',
  });

  return `${baseUrl}?${params.toString()}`;
}
