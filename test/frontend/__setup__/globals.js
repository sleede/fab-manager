// global variable
global.Application ||= {};
global.Application.Components ||= {};
global.Application.Components.component ||= function (name, component) { /* mock */ };

global.Fablab ||= {};
global.Fablab.machinesModule = true;
global.Fablab.plansModule = true;
global.Fablab.spacesModule = true;
global.Fablab.trainingsModule = true;
global.Fablab.storeModule = true;
global.Fablab.walletModule = true;
global.Fablab.publicAgendaModule = true;
global.Fablab.statisticsModule = true;
global.Fablab.defaultHost = 'localhost';
global.Fablab.trackingId = 'G-123456-7';
global.Fablab.adminSysId = 1;
global.Fablab.activeProviderType = 'DatabaseProvider';
global.Fablab.storeHidden = false;
global.Fablab.locale = 'fr';
global.Fablab.moment_locale = 'fr';
global.Fablab.summernote_locale = 'fr-FR';
global.Fablab.fullcalendar_locale = 'fr';
global.Fablab.intl_locale = 'fr-FR';
global.Fablab.intl_currency = 'EUR';
global.Fablab.timezone = 'Europe/Paris';
global.Fablab.translations = {
  app: {
    shared: {
      buttons: {
        confirm_changes: 'Confirm changes',
        consult: 'Consult',
        edit: 'Edit',
        change: 'Change',
        delete: 'Delete',
        browse: 'Browse',
        cancel: 'Cancel',
        close: 'Close',
        clear: 'Clear',
        today: 'Today',
        confirm: 'Confirm',
        save: 'Save',
        yes: 'Yes',
        no: 'No',
        apply: 'Apply'
      },
      messages: {
        you_will_lose_any_unsaved_modification_if_you_quit_this_page: 'You will lose any unsaved modification if you quit this page',
        you_will_lose_any_unsaved_modification_if_you_reload_this_page: 'You will lose any unsaved modification if you reload this page',
        payment_card_declined: 'Your card was declined.'
      }
    }
  }
};
global.Fablab.weekStartingDay = 1;
global.Fablab.d3DateFormat = '%d/%m/%y';
global.Fablab.uibDateFormat = 'dd/MM/yyyy';
global.Fablab.maxProofOfIdentityFileSize = 5242880;
global.Fablab.sessionTours = [];
